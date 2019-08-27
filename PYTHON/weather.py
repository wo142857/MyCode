#! /usr/bin/env python
#! -*- coding:utf-8 -*-

import sys
import re
import string
import urllib2
from HTMLParser import HTMLParser
from pypinyin import pinyin, lazy_pinyin
import MySQLdb
import time
from datetime import datetime import datetime as dt def get_html(city):
	url = "http://www.tianqihoubao.com/weather/top/%s.html" % city
#	print url
	try:
		content = urllib2.urlopen(url).read()
	except urllib2.HTTPError:
		return city
	else:
		html = unicode(content, "GB2312")
#		print(html)
		return html
	
def parse_html(html):
	pass

class myHtmlParser(HTMLParser):
	
	cityname = ''

	selected = ('html', 'body', 'form', 'div', 'div', 'div', 'div', 'table', 'tr', 'td', 'a')

	get_set = ('html/body/form/div/div/div/div/table/tr/td/a', 'html/body/form/div/div/div/div/table/tr/td')

	weather_info_pool = {}

	def reset(self):  
		HTMLParser.reset(self)  
		self._level_stack = []  
		self._flag = False
		self._mark = ''

	def handle_starttag(self, tag, attrs):
		if tag in m.selected:
			self._level_stack.append(tag)
	
	def handle_endtag(self, tag):  
		if self._level_stack and tag in m.selected and tag == self._level_stack[-1]:
			self._level_stack.pop()
		
	
	def handle_data(self, data):
		tmp_stack = "/".join(self._level_stack)
#		print tmp_stack

		if tmp_stack == m.get_set[0]:
#			print 0, data.strip()
			date = data.strip()
			m.weather_info_pool[date[:10]] = []
			self._mark = date[:10]
			self._flag = True

		if self._flag and tmp_stack == m.get_set[1]:
#			print m.cityname
			if data.strip() != m.cityname:
				 if len(data.strip()) != 0 and data.strip() != u'-':
#					print 1, data.strip(), len(data.strip())
					m.weather_info_pool[self._mark].append(data.strip())
			else:
#				print '--------------------------------------------------------------yes'
				self._mark = ''
				self._flag = False


'''
def dict_dump(obj):

	getIndent = lambda level: '\t' * level

	quoteStr = lambda s:'"' + s.replace('"', '\\"') + '"'

	wrapKey = lambda val:if isinstance(val,int): 
			"[" + val + "]"
		elif isinstance(val, str):
			"[" + quoteStr(val) + "]"
		else:
			"[" + str(val) + "]"
	
	wrapVal = lambda val, level:
		if isinstance(val, dict):
			dumpObj(val, level)
		elif isinstance(val, int):
			val
		elif isinstance(val, str):
			quoteStr(val)
		else:
			str(val)
		
	dumpObj = lambda obj, level:
		if isinstance(obj, dict):
			wrapVal(obj)
		
		level = level + 1
		tokens = {}
		tokens[len(tokens) + 1] = "{"
		for k, v in obj.items():
			tokens[len(tokens) + 1] = getIndent(level) + wrapKey(k) + " = " + wrapVal(v, level) + ","
		
			tokens[len(tokens) + 1] = getIndent(level - 1) + "}"
		
		table.concat(tokens, "\n")
		
	return dumpObj(obj, 0) 
	

	
	if isinstance(args, dict):
		for k, v in args.items():
			dict_dump(v)
	elif isinstance(args, list):
		for item in args:
			dict_dump(item)
	else:
		print args
	'''


def word_to_pinyin(**kw):
	pinyin = lazy_pinyin('%s' % kw['word'])
	ret = ''
	for k in pinyin:
		ret = ret + k
	return ret



if __name__ == '__main__':

	# 连接mysql数据库
	connect = MySQLdb.connect(
			host = '192.168.61.11',
			user = 'sa',
			passwd = '123456',
			db = 'bak_pingan',
			port = 3306,
			charset = 'utf8'
		)
	cur = connect.cursor()

	# 获取城市名称列表	
	city_count = cur.execute('select cityName, cityCode from cityInfo')
	city_infos = cur.fetchmany(city_count)
#	print type(city_names), len(city_names), u'%s' % city_names[5]
	
	# 遍历城市列表
	for city_info in city_infos:
		print city_info[0]
		city_pinyin = ''
		if city_info[0] == u'长治':
			city_pinyin = 'changzhi'
		elif city_info[0] == u'沈阳':
			city_pinyin = 'shenyang'
		elif city_info[0] == u'厦门':
			city_pinyin = 'xiamen'
		elif city_info[0] == u'洛阳':
			city_pinyin = 'lvyang'
		elif city_info[0] == u'商洛':
			city_pinyin = 'shanglv'
		elif city_info[0] == u'东莞':
			city_pinyin = 'dongguang'
		elif city_info[0] == u'西沙':
			city_pinyin = 'xishaqundao'
		elif city_info[0] == u'都匀':
			city_pinyin = 'duyun'
		elif city_info[0] == u'昌都':
			city_pinyin = 'changdu'
		elif city_info[0] == u'那曲':
			city_pinyin = 'naqu'
		elif city_info[0] == u'武都':
			city_pinyin = 'wudu'
		elif city_info[0] == u'果洛':
			city_pinyin = 'guolv'
		elif city_info[0] == u'库尔勒':
			city_pinyin = 'kuerle'
		elif city_info[0] == u'阿图什':
			city_pinyin = 'atushi'
		elif city_info[0] == u'喀什':
			city_pinyin = 'kashi'
		elif city_info[0] == u'阿勒泰':
			city_pinyin = 'aletai'
		elif city_info[0] == u'邵阳':
			city_pinyin = 'shaoyangxian'
		else:
			city_pinyin = word_to_pinyin(word = u'%s' % city_info[0])	# 转换成拼音

		# 爬取当前城市的历史天气
		html = get_html(city_pinyin)
	
		with open('/home/liu/scripts/cityList.py','at') as f:
			line = "['%s','%s','%s']," % (city_info[0], city_info[1], city_pinyin)
			f.write(line.encode('utf-8'))

		if html == city_pinyin:
#			error_city.append(city_info[0])
			continue
		
	
		# 解析html
		m = myHtmlParser()
		m.cityname = city_info[0]
		m.feed(html)
		
		# insert into pool
		weather_data_pool = []
		
		for k, v in m.weather_info_pool.items():
			tmp_pool = []
			tmp_pool.append(city_info[0])
			tmp_pool.append(city_info[1])
			tmp_pool.append(k)
			for vv in v:
				m = vv.split()
				if len(m) > 1:
					for mm in m:
						tmp_pool.append(mm)
				else:
					tmp_pool.append(vv)

			tmp_day_pool = []
			tmp_night_pool = []
			for i, value in enumerate(tmp_pool):
				if value == '-':
					value = ''

				if i <= 1:
					 tmp_day_pool.append(value)
					 tmp_night_pool.append(value)
				elif i == 2:

					end_time = datetime.now()
					start_time = end_time - dt.timedelta(30)

#					print value < start_time.strftime('%Y-%m-%d'), value > end_time.strftime('%Y-%m-%d')
#					if value < start_time.strftime('%Y-%m-%d') or value > end_time.strftime('%Y-%m-%d'):
#						print 'continue'
#						tmp_day_pool.pop()
#						tmp_night_pool.pop()
#						continue
						
					day_time = "%s 08:00:00" % value
					night_time = "%s 20:00:00" % value

#					day_time = time.strptime(day_str, "%Y-%m-%d %H:%M:%S")
#					night_time = time.strptime(night_str, "%Y-%m-%d %H:%M:%S")

					tmp_day_pool.append(day_time)
					tmp_night_pool.append(night_time)
				elif i == 6:
					if re.match(r'^\W', value) == None:
						p = re.search(r'^[\d]+', value).group()
					elif re.match(r'^\W', value).group != None:
						p = re.search(r'^\W[\d]+', value).group()

					tmp_night_pool.append(p)
				elif i == 10:
					if re.match(r'^\W', value) == None:
						p = re.search(r'^[\d]+', value).group()
					elif re.match(r'^\W', value).group != None:
						p = re.search(r'^\W[\d]+', value).group()

					tmp_day_pool.append(p)
	
				elif i > 2 and i < 6 :
					tmp_night_pool.append(value)
				elif i > 6 and i < 10:
					tmp_day_pool.append(value)

			if len(tmp_day_pool) == 7:
				weather_data_pool.append(tmp_day_pool)

			if len(tmp_night_pool) == 7:
				weather_data_pool.append(tmp_night_pool)


		# insert into mysql
		sql = 'insert into weatherInfo2 (cityName, cityCode, date, text, windDirection, windScale, temperature) values (%s, %s, %s, %s, %s, %s, %s)'
		cur.executemany(sql, weather_data_pool)
		connect.commit()

	# dump dict
	#dict_dump(weather_data_pool)

	cur.close()
	connect.close()


