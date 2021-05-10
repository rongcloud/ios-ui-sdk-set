#coding=utf-8

import os

delete_files=["RCCall.mm","RCCXCall.m"]

start_key = "RCCallKit_Delete_Start"
end_key = "RCCallKit_Delete_end"

def delete_used(file_path):
	print(file_path)

	f = open(file_path,"r")
	lines = f.readlines()
	f.close()

	# print(lines)

	result = []
	flag = False
	for l in lines:
		if start_key in l:
			flag = True
		elif end_key in l:
			flag = False

		if flag is True:
			continue
		result.append(l)

	f = open(file_path,"w")
	f.writelines(result)
	f.close()


for root,dirs,files in os.walk("./CallKit"):
	for file in files:
		if file in delete_files:
			print("will delete %s" % file)
			delete_used(os.path.join(root,file))

