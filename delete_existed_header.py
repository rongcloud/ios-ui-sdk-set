#coding=utf-8

import os

default_folders = ["IMKit","Sight","Sticker","ContactCard","iFlyKit","CallKit"]

exist_headers = []

for folder_name in default_folders:
	print("enter folder : %s"  %folder_name)
	for root,dirs,files in os.walk(folder_name):
		for f in files:
			if f.endswith(".h"):
				if f not in exist_headers:
					exist_headers.append(f)
				else:
					path = os.path.join(root,f)
					print("delete exist header : %s" %path)
					os.remove(path)
					

print("deleted all repeated header")


