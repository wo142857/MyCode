local only = require ("only")
local scan = require ("scan")
local mysql_api = require ("mysql_pool_api")

local ROW_COUNT = 10896051		--> SGID表总行数
local DB_LINK   = "app_sort_tt"		--> link文件配置的sql数据库地址

local TABLE = {
		t1 = "SG",
		t2 = "line_node",
		t3 = "roadRelation",
		t4 = "road_LR",
	}				--> sql table list

local POOL = {}				--> 存放将写入sql的记录
local POOL_FINE = {}			--> 存放最优左右转记录

local function select_from_sql (parameter)

--	only.log("D", string.format("select from sql parameter = %s", scan.dump(parameter)))

	local sql = string.format(
		"SELECT %s FROM %s WHERE %s;",
		parameter["field"],
		parameter["table"],
		parameter["condition"])
		
	local ok, ret = mysql_api.cmd(DB_LINK, "SELECT", sql)

	if not ok and not ret then
		only.log("E",string.format(
			"%s : select sql error!",
			parameter["condition"]))
		return {}
	end

	return ret
end

local function get_turning_info (parameter)
	
--	only.log("D", string.format("get turning info parameter = %s", scan.dump(parameter)))

	local diff_ang = parameter["ang2"] - parameter["ang1"]

	--> 修改负值夹角
	if diff_ang < 0 then
	        diff_ang = diff_ang + 360 
	end 
	
	local turn_mark 
	if diff_ang > 195 and diff_ang < 345 then
	        turn_mark = "left"
	elseif diff_ang < 165 and diff_ang > 15 then
	        turn_mark = "right"
	elseif diff_ang >= 345 or diff_ang <= 15 then
	        turn_mark = "straight"
	elseif diff_ang >= 165 and diff_ang <= 195 then
	        turn_mark = "U"
	end 
	
	return turn_mark, tonumber(diff_ang)

end

local function update_turning_sgid(parameter)

--	only.log("D", string.format("update turning parameter = %s", scan.dump(parameter)))

	--> 跳过name相同的左右转
	if parameter["turn"] == "left" or parameter["turn"] == "right" then
		if parameter["name1"] == parameter["name2"] then
			return nil
		end
	end

	local ref_ang, nil_v
	if parameter["turn"] == "left" then
		ref_ang, nil_v = 270, 630
	elseif parameter["turn"] == "right" then
		ref_ang, nil_v = 90, 450
	elseif parameter["turn"] == "straight" then
		ref_ang, nil_v = 0, 360
	elseif parameter["turn"] == "U" then
		ref_ang, nil_v = 180, 540
	end

	POOL_FINE[parameter["sg1"]] = POOL_FINE[parameter["sg1"]] or {}

	POOL_FINE[parameter["sg1"]][parameter["turn"]] = POOL_FINE[parameter["sg1"]] and POOL_FINE[parameter["sg1"]][parameter["turn"]] or {}

	local ori_ang = POOL_FINE[parameter["sg1"]][parameter["turn"]]["diff"] or nil_v
	local ori_diff = math.abs(tonumber(ori_ang) - ref_ang)
	local cur_diff = math.abs(parameter["diff"] - ref_ang)

--	only.log("D", string.format("ori_ang:%s; ori_diff:%s; cur_ang:%s; cur_diff:%s", 
--			ori_ang, ori_diff, parameter["diff"], cur_diff))

	if ori_diff >= cur_diff then

		local tmp_f = { [parameter["turn"]] = {["id"] = "", ["diff"] = ""}}
		POOL_FINE[parameter["sg1"]] = POOL_FINE[parameter["sg1"]] and POOL_FINE[parameter["sg1"]] or tmp_f
		POOL_FINE[parameter["sg1"]][parameter["turn"]] = POOL_FINE[parameter["sg1"]][parameter["turn"]] and POOL_FINE[parameter["sg1"]][parameter["turn"]] or {}

		POOL_FINE[parameter["sg1"]][parameter["turn"]]["id"] = parameter["sg2"]
		POOL_FINE[parameter["sg1"]][parameter["turn"]]["diff"] = parameter["diff"]
	end
end

local function special_line(line, num)
	local sql_field = num == 1 and "Sline_id" or "Eline_id"
	local s_ok = select_from_sql{
				field = "RR_SG",
				table = TABLE["t1"],
				condition = string.format("%s = '%s'",
					sql_field, line)
			}
	return #s_ok > 0 and true or false
end

local function insert_into_table(parameter)
	
--	only.log("D",string.format("insert into table parameter = %s", scan.dump(parameter)))				

	--> 删除SGID相同的line
	for k, v in pairs(parameter["sg2"]) do
		if v["RR_SG"] == parameter["sg1"]["id"] then
			table.remove(parameter["sg2"], k)
		end
	end

	--> 添加转弯信息，插入POOL
	--> 选择最佳左右转，插入POOL_FINE
	
	for k, v in pairs(parameter["sg2"]) do

		repeat
		--> 匝道，递归
		if v["mark1"] == '1' then
			if not parameter["cro"] or (parameter["cro"] and not parameter["cro"][v["line_id"]]) then
				
				parameter["cro"] = parameter["cro"] or {}

				parameter["cro"][v["line_id"]] = true	--> set, 途径匝道

--				only.log("D",string.format("recursion : %s", scan.dump(v)))			

				local coor2_l = select_from_sql {
							field = "RR_SG, coor1, coor2, ang, line_id, mark1, len, name_id",
							table = TABLE["t2"],
							condition = string.format("coor1 = '%s'",
								v["coor2"])
						}
				insert_into_table {
						mark = "l",
						sg1  = parameter["sg1"],
						sg2  = coor2_l,
						cro  = parameter["cro"]	--> set
				}
			end
		else
			--> 转弯信息
			local turn_info, diff_ang = get_turning_info {
					ang1 = tonumber(parameter["sg1"]["ang"]),
					ang2 = tonumber(v["ang"])
				}

			--> 跳过line为SGID的最后一条，且距离小于50米的情况
			if special_line(v["line_id"], -1) and tonumber(v["len"]) < 50 and v["mark1"] ~= "1" then
--				only.log("D","break")
				break
			end

			local tmp = {
					--> 转弯信息
					turn  = turn_info,
					diff  = diff_ang,
					sg1   = parameter["sg1"]["id"],
					sg2   = v["RR_SG"],
					cross = parameter["sg1"]["coor"] .. ";" .. v["coor1"],
					mark  = parameter["mark"]
				}
			
			table.insert(POOL, tmp)
			
			--> 最佳左右转
			update_turning_sgid{
					turn  = turn_info,
					diff  = diff_ang,
					sg1   = parameter["sg1"]["id"],
					name1 = parameter["sg1"]["name"],
					sg2   = v["RR_SG"],
					name2 = v["name_id"]
				}
		end
		until true
	end
end

local function recursion(parameter)
	local ret = select_from_sql{
				field = "RR_SG, mark1, coor2, coor1",
				table = TABLE["t2"],
				condition = string.format("coor2 = '%s'",
					parameter["coor"])
			}
	insert_into_table {
			mark = "l",
			sg1  = {
				id = parameter["sg1"],
				coor = parameter["coor"],
				},
			sg2  = {
				mark1 = "1",
				RR_SG = "",
				}
		}
	
	
end

local function insert_into_mysql(table, tab)

	for k, v in pairs(table) do

--		only.log("D",string.format("POOL insert into mysql parameter = %s", scan.dump(v)))				

		local sql = string.format("INSERT INTO %s (SG1,SG2,MARK,V_CROSS,NEXT,DIFF) VALUES ('%s','%s','%s','%s','%s','%s');",
				TABLE["t3"], table[k]["sg1"], table[k]["sg2"],table[k]["mark"],table[k]["cross"],table[k]["turn"],table[k]["diff"])
		local ok, ret = mysql_api.cmd(DB_LINK,"INSERT",sql)
		if not ok or not ret then
			only.log("E","insert into mysql error!")
		end
	end

	for k, v in pairs(tab) do

--		only.log("D",string.format("POOL FINE insert into mysql parameter = %s", scan.dump(v)))				

		--> 空值处理
		tab[k]["left"]     = tab[k]["left"] and tab[k]["left"] or {}
		tab[k]["right"]    = tab[k]["right"] and tab[k]["right"] or {}
		tab[k]["straight"] = tab[k]["straight"] and tab[k]["straight"] or {}
		tab[k]["U"]        = tab[k]["U"] and tab[k]["U"] or {}


		local sql = string.format("INSERT INTO %s (sgid,left_sg,right_sg,straight,u) VALUES ('%s','%s','%s','%s','%s');",
				TABLE["t4"], k, tab[k]["left"]["id"],tab[k]["right"]["id"],tab[k]["straight"]["id"],tab[k]["U"]["id"])
		local ok, ret = mysql_api.cmd(DB_LINK,"INSERT",sql)
		if not ok or not ret then
			only.log("E","insert into mysql error!")
		end
	end
end

local function handle()
	
	-- 循环取SGID，每次取固定条数
	--
	-- 每次50000条
	local Step = 50000

	local start_row = 1
	local end_row   = start_row + Step

	repeat
		local sgids = select_from_sql{
				field = "RR_SG, Ecoor1, Ecoor2, Elen, Eang, Ename_id",			--> SELECT
				table = TABLE["t1"],				--> FROM
--				condition = string.format("RR_SG = '1196549|15'")
				condition = string.format("id >= %d and id < %d",
					start_row, end_row)			--> WHERE
			}

		for k_sgid, v_sgid in pairs(sgids) do
			
--			only.log("D",string.format("sgid = %s", scan.dump(v_sgid)))				

			-------------------------------------------Ecoor1---------------------------------------------------
			--> 同一条RR_SG
			--> Elen小于100
			-------------------------------------------Ecoor1---------------------------------------------------
			if tonumber(v_sgid["Elen"]) < 100 then

--				only.log("D","ECoor1 start!")				

				local lines_Ecoor1 = select_from_sql{
							field = "RR_SG",
							table = TABLE["t2"],
							condition = string.format("coor1 = '%s'",
								v_sgid["Ecoor1"])
						}
				
				--> 移除RR_SG不相同的line
				for k, v in pairs(lines_Ecoor1) do
					if v["RR_SG"] ~= v_sgid["RR_SG"] then
						table.remove(lines_Ecoor1, k)
					end
				end

				for k_line_Ecoor1, v_line_Ecoor1 in pairs(lines_Ecoor1) do

--					only.log("D",string.format("Ecoor1 line_id = %s", scan.dump(v_line_Ecoor1)))				

					local lines_Ecoor1_coor2 = select_from_sql{
							field = "RR_SG, ang, len, coor1, name_id, mark1, line_id",
							table = TABLE["t2"],
							condition = string.format("coor1 = '%s'",
								v_sgid["Ecoor1"])
						}

					--> insert into table
					insert_into_table{
								mark = "bp",			--> 最后一条line的起点连接
								sg1  = {
									id   = v_sgid["RR_SG"],
									ang  = v_sgid["Eang"],
									coor = v_sgid["Ecoor1"],
									name = v_sgid["Ename_id"]
									},			--> 起始SGID
								sg2 = lines_Ecoor1_coor2,	--> 符合条件的line
							}
				end
			end
			----------------------------------------------------------------------------------------------------

			-------------------------------------------Ecoor2---------------------------------------------------
			--> 1.直接连接
			--> 2.向前跨过一条line的连接
			--> 3.向前跨过两条line的连接
			--> 4.跨过匝道的连接 (递归)
			----------------------------------------------------------------------------------------------------

			--> 直接连接
			
--			only.log("D","Ecoor2 direct start!")

			local lines_Ecoor2 = select_from_sql{
						field = "RR_SG, coor2, len, ang, mark1, line_id, coor1, name_id",
						table = TABLE["t2"],
						condition = string.format("coor1 = '%s'",
							v_sgid["Ecoor2"])
					}
			insert_into_table{
						mark = "p",
						sg1 = {
							id   = v_sgid["RR_SG"],
							ang  = v_sgid["Eang"],
							coor = v_sgid["Ecoor2"],
							name = v_sgid["Ename_id"]
							},
						sg2 = lines_Ecoor2,
					}

			--> 只保留line为对应SGID的第一条line的情况
			for k, v in pairs(lines_Ecoor2) do
				if special_line{v["line_id"], 1} then
					table.remove(lines_Ecoor2, k)
				end
			end
			
			--> 向前跨过一条line的连接
			--> :	length < 100
			-->	ang    < 45
			-->     mark  ~= '1'

--			only.log("D","Ecoor2 cross over 1 start!")

			for k_1, v_1 in pairs(lines_Ecoor2) do
				local len_check = tonumber(v_1["len"]) < 100
				local ang = {
						a1 = tonumber(v_sgid["Eang"]),
						a2 = tonumber(v_1["ang"])
					}
				local ang_diff = ang["a1"] > ang["a2"] and ang["a1"] - ang["a2"] or ang["a2"] - ang["a1"]
				ang_diff = ang_diff >180 and 360 - ang_diff or ang_diff
				local ang_check = ang_diff < 60
				local mar_check = v_1["mark1"] ~= '1'
				if len_check and ang_check and mar_check then
					local lines_1 = select_from_sql{
								field = "RR_SG, coor2, len, ang, mark1, line_id, coor1, name_id",
								table = TABLE["t2"],
								condition = string.format("coor1 = '%s'",
									v_1["coor2"])
							}
					insert_into_table{
							mark = "s",
							sg1  = {
								id   = v_sgid["RR_SG"],
								ang  = v_sgid["Eang"],
								coor = v_sgid["Ecoor2"],
								name = v_sgid["Ename_id"]
								},
							sg2  = lines_1,
						}

					--> 向前跨过两条line；只找line为对应SGID最后一条的情况
					
--					only.log("D","Ecoor2 cross over 2 start!")
					--[[	
					for k, v in pairs(lines_1) do
						if not special_line(v["line_id"], -1) then
							table.remove(lines_1, k)
						end
					end
					--]]
					
					-->: length < 100 and sum length < 100
					-->  mark ~= '1'
					for k_2, v_2 in pairs(lines_1) do
						local len_2_check = tonumber(v_2["len"]) < 100 and tonumber(v_1["len"]) + tonumber(v_2["len"]) < 100
						local mar_2_check = v_2["mark1"] ~= "1"
						if len_2_check and mar_2_check then
							local lines_2 = select_from_sql{
										field = "RR_SG, ang, len, line_id, coor1,name_id, mark1",
										table = TABLE["t2"],
										condition = string.format("coor1 = '%s'",
											v_2["coor2"])
									}
							insert_into_table{
									mark = "ss",
									sg1  = {
										id   = v_sgid["RR_SG"],
										ang  = v_sgid["Eang"],
										coor = v_sgid["Ecoor2"],
										name = v_sgid["Ename_id"]
										},
									sg2  = lines_2,
								}
						end
					end

				end
			end

			--> 跨过匝道连接
			--[[	
			if v_sgid["mark1"] == '1' then
				recursion{
						sg1  = v_sgid["RR_SG"],
						coor = v_sgid["Ecoor2"],
					}
			end
			--]]
			----------------------------------------------------------------------------------------------------
			

		end
	
		insert_into_mysql(POOL, POOL_FINE)
		POOL, POOL_FINE = {}, {}

		only.log("D", string.format("row id : %s end!", end_row))

		start_row = end_row
		end_row   = end_row + Step 
	until start_row > ROW_COUNT
	insert_into_mysql(POOL, POOL_FINE)
end


handle()
