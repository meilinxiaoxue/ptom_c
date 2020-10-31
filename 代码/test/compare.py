# !/usr/bin/env python
# -*- coding:utf-8 -*- 

import os
import re

patten = re.compile("%.+")
patten2 = re.compile("%{(.|\s)+?%}")

def debugfile(file):
	global patten
	content = ""
	fp = open(file,"r")
	try:
		content = fp.read()
		content = re.sub(patten2,"",content)
		content = re.sub(patten,"",content)
		content = content.replace("%","")
		content = content.replace(",","")
		#content = content.replace(" ","")
	except:
		print("%s" % file)
	finally:
		fp.close()
	return content

def subfile(file):
	global patten
	content = ""
	fp = open(file,"r")
	try:
		content = fp.read()
		content = re.sub(patten2,"",content)
		content = re.sub(patten,"",content)
		content = content.replace("%","")
		content = content.replace("\n","")
		content = content.replace("\r","")
		content = content.replace(",","")
		content = content.replace(" ","")
		content = content.replace("\x09","")
		content = content.replace("...","")
		content = content.replace(";","")
	except:
		print("%s" % file)
	finally:
		fp.close()
	return content

def compare(file1,file2):
	c1 = subfile(file1)
	c2 = subfile(file2)
	
	if(c1 == c2):
		return 1
	else:
		fp = open("c1","w")
		fp.write(debugfile(file1))
		fp.close()
		fp = open("c2","w")
		fp.write(debugfile(file2))
		fp.close()	
		return 0

def main():
	m_dir = "D:\\Reverse\\ptom\\代码\\test\\m"
	m2_dir = "D:\\Reverse\\ptom\\代码\\test\\m2"
	
	mfiles = os.listdir(m_dir)
	for mfile in mfiles:
		if(mfile[-2:] != ".m"):
			continue
		if(compare("%s\\%s" % (m_dir,mfile),"%s\\%s" % (m2_dir,mfile))==0):
			print("%s not equal %s" % ("%s\\%s" % (m_dir,mfile),"%s\\%s" % (m2_dir,mfile)))
			break
		else:
			print("%s compare good" % mfile)

if(__name__ == '__main__'):
	main()