# coding: utf-8

import sys
reload(sys)
sys.setdefaultencoding("utf-8")

import re,time,requests
import bs4,requests,pprint
import MySQLdb
import json

def _sqlInit():
    connect = MySQLdb.connect(
            host = '127.0.0.1',
            user = 'root',
            passwd = '123456',
            db = 'helptest_infos',
            port = 3306,
            charset = 'utf8'
        )

    return connect


def queryList(t):
    connect = _sqlInit()
    _cur = connect.cursor()

    _q_sql = 'SELECT * FROM %s;' % t

    _cur.execute(_q_sql)

    res = _cur.fetchall()

    return res

def get_result(word):
    # 有道词典 api
    url = 'http://fanyi.youdao.com/translate?smartresult=dict&smartresult=rule&smartresult=ugc&sessionFrom=null'
    # 传输的参数，其中 i 为需要翻译的内容
    key = {
        'type': "AUTO",
        'i': word,
        "doctype": "json",
        "version": "2.1",
        "keyfrom": "fanyi.web",
        "ue": "UTF-8",
        "action": "FY_BY_CLICKBUTTON",
        "typoResult": "true"
    }
    # key 这个字典为发送给有道词典服务器的内容
    response = requests.post(url, data=key)
    # 判断服务器是否相应成功
    if response.status_code == 200:
        # 通过 json.loads 把返回的结果加载成 json 格式
        result = json.loads(response.text)
        # print ("输入的词为：%s" % result['translateResult'][0][0]['src'])
        # print ("翻译结果为：%s" % result['translateResult'][0][0]['tgt'])
        return result['translateResult'][0][0]['tgt']
    else:
        print("有道词典调用失败")
        # 相应失败就返回空
        return None

def _translate(row, obj, field, t):
    _set, _ori = '', ''
    n = 0
    while n < len(obj):
        v = get_result(row[obj[n]])
        _set = _set + '%s = "%s"' % (field[n], v)
        _ori = _ori + '%s = "%s"' % (field[n].rstrip('_zh'), row[obj[n]])
        if n == 0 and len(obj) > 1 :
            _set = _set + ', '
            _ori = _ori + ' AND '
        n = n + 1


    _sql = 'UPDATE %s SET %s WHERE id = %d AND %s;' % (t, _set, row[0], _ori)
    print(_sql)

    return _sql


if __name__ == '__main__':
    print("***** START ***** " + time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(time.time())))
    start = time.time()

    _tables = ['answer', 'question', 'result', 'test']
    _objs   = [[4], [3], [2, 6], [2, 3]]
    _fields = [['answer_zh'], ['question_zh'], ['answer_zh', 'resultinfo_zh'], ['title_zh', 'info_zh']]

    i = 0
    while i < len(_tables):
        _list = queryList(_tables[i])
        if _list :
            for row in _list:
                _sql = _translate(row, _objs[i], _fields[i], _tables[i])

        i = i + 1

    print("***** END *****" + " waste time: ", (time.time() - start))
