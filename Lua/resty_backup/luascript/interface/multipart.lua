local upload = require "resty.upload" ;
function parse_parthead( s )
    local _filename ;
    local _vname, _fileinfo = string.match( s, 'form%-data;%s*name="(.-)"(.*)' );
    if( type(_fileinfo) == "string" and #_fileinfo> 10 ) then
        _filename = string.match( _fileinfo, 'filename="(.+)"' );
    end;
    return _vname, _filename;
end;

function proc_multipart_form( cmd )
	local _chunk_size = config.fileupload.chunksize or 4096
	local _temp_filedir = config.fileupload.tmppath or "/tmp/";
	local _filecount = 0;

	local _file, _vname, _value, _filesize, _filename, _fileext, _filepath, _filemd5, _filesha, _md5o;
	local _form = upload:new(_chunk_size) ;
	local _POST, _FILE, _rcode;
	if( _form == nil ) then
	ngx.req.read_body();
        _POST = ngx.req.get_post_args();
		return 0, _POST; 
	end; -- not multipart
	_form:set_timeout(0) -- 1 sec
	if( not config.fileupload.allow[cmd] ) then -- permit deny
		return -700;
	end;
	
	_FILE = {};
	_POST = {};

	while true do
		local _type, _res, _err = _form:read()
		if not _type then return -701; end;
		
		if _type == "header" then
			if _res[1] ~= "Content-Type" then
				_vname, _filename = parse_parthead( _res[2] );
				--_LOG( "RES2="..tostring(_res[2] ) );
				--_LOG( "FILE="..tostring(_filename) );
				--_LOG( "VNAME="..tostring(_vname) );
        			if _filename and #_filename>0 then
						_fileext = _filename:match( ".*%.(.*)" );
						_filepath = config.fileupload.tmppath..os.tmpname(); 
	           			_file = io.open(_filepath,"w+");
						_filesize = 0;
               			if not _file then
                   				return -702 ; -- create tmp file error.
               			end
    					_md5o = md5.new();
        			end
        		end
    		elseif _type == "body" then
		        if _file then
            			_file:write(_res)
            			_md5o:update( _res );
            			_filesize= _filesize + tonumber(string.len(_res))    
        		else
			    _value = _res;
        		end
    		elseif _type == "part_end" then
		        if _file then
				_file:close()
				_file = nil

				_FILE[ _vname ] = {};
				_FILE[ _vname ][ 'path' ] = _filepath;
				_FILE[ _vname ][ 'origname' ] = _filename;
				_FILE[ _vname ][ 'md5' ] = sstr.to_hex( _md5o:final() );
				_FILE[ _vname ][ 'size' ] = _filesize;
	    			_md5o = nil;
			else
				if _vname then
					_POST[_vname] = _value ;
				end;
        		end
    		elseif _type == "eof" then
        		break
    		else
    		end
	end
	return 0, _POST, _FILE;
end;
