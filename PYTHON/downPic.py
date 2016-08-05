#!/usr/bin/python 
#coding:utf8
import re
import urllib

def getHtml(url):
    page = urllib.urlopen(url)
    html = page.read()
    return html


filename = '/home/liu/Public/6w_url.dat'
with open(filename, 'rt') as f:
    for line in f:
	url = line.split(",")[5]
	print(url)
        name = url.split('=')[-1]
	print(name)
	html = getHtml(url)
        path = '/home/liu/Public/pic'
        urllib.urlretrieve(url,'{0}/{1}'.format(path, name))

	


