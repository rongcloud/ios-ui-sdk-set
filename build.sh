#!/bin/bash

#  Created by qixinbing on 2021/2/26.
#  Copyright (c) 2021 RongCloud. All rights reserved.

#Version=5.0.0
#Release_Node=113

## 1. 更新 git 仓库
git checkout main
git reset --hard origin/main
git clean -dfx
git pull

## 2. 更新所有的代码
function update_sdk(){
	src_name=$1
	target_name=$2
	build_host=$(hostname)
        if [ ${build_host} = "rce" ];
        then
                cp /var/lib/jenkins/jobs/iOS-SDK-Release/builds/${Release_Node}/archive/output/${src_name}_SourceCode_*.zip ./
        elif [ ${build_host} = "jenkinsdeMac-mini.local" ];
        then
                cp /Users/jenkins/archives/iOS-SDK-Release/${Release_Node}/${src_name}_SourceCode_*.zip ./
        else
                exit 1
        fi
	unzip ${src_name}_SourceCode_*.zip
	rm -rf ${target_name}/
	mv ${src_name}/${src_name} ${target_name}
	rm -rf ${src_name}
	rm -rf ${src_name}_SourceCode_*.zip
}

update_sdk RongIMKit IMKit
update_sdk RongSticker Sticker
update_sdk RongSight Sight
update_sdk RongiFlyKit iFlyKit
update_sdk RongContactCard ContactCard
update_sdk RongLocationKit LocationKit
update_sdk RongCallKit CallKit

if [[ "$OSTYPE" == "darwin"* ]]; then
  ## 剔除 ifly 的敏感信息
  sed -i '' -e 's?^#define iFlyKey.*$?#define iFlyKey @\"\"?' iFlyKit/Extention/RCiFlyKitExtensionModule.m
  ## 修改 RCIMKitVersion
  sed -i '' -e 's?^static NSString \*const RCIMKitVersion.*$?static NSString *const RCIMKitVersion = @\"'$Version'_opensource\";?' IMKit/RCIM.m
  ## 修改 __RongCallKit__Version
  sed -i '' -e 's?^static NSString \*const __RongCallKit__Version.*$?static NSString *const __RongCallKit__Version = @\"'$Version'_opensource\";?' CallKit/RCCall.mm
else
  sed -i -e 's?^#define iFlyKey.*$?#define iFlyKey @\"\"?' iFlyKit/Extention/RCiFlyKitExtensionModule.m
  sed -i -e 's?^static NSString \*const RCIMKitVersion.*$?static NSString *const RCIMKitVersion = @\"'$Version'_opensource\";?' IMKit/RCIM.m
  sed -i -e 's?^static NSString \*const __RongCallKit__Version.*$?static NSString *const __RongCallKit__Version = @\"'$Version'_opensource\";?' CallKit/RCCall.mm
fi


## 3. 删除重复存在的 .h

python delete_existed_header.py
python delete_unuse_callkit.py

## 4. 统一管理资源文件

res_path="Resources"

if [ ! -d $res_path ];then
	mkdir $res_path
fi

rsync -a IMKit/Resource/* $res_path/ && rm -rf IMKit/Resource/
rsync -a Sticker/Resource/* $res_path/ && rm -rf Sticker/Resource/
rsync -a iFlyKit/Resource/* $res_path/ && rm -rf iFlyKit/Resource/
rsync -a CallKit/Resources/* $res_path/ && rm -rf CallKit/Resources/

#sed -i ""  -e 's/[0-9]\.[0-9]\{1,2\}\.[0-9]\{1,2\}/'"$Version"'/' RongCloudOpenSource.podspec

# 第一个替换：修复s.version行
sed -i '' -E "/s\.version.*=/s/\"[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}(\.[0-9]{1,3})?\"/\"$Version\"/g" RongCloudOpenSource.podspec

# 第二个替换：修复kit.dependency行中的版本号
sed -i '' -E "/kit\.dependency.*RongCloudIM\/IMLib/s/'[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}(\.[0-9]{1,3})?'/'$Version'/g" RongCloudOpenSource.podspec


## 5. 提交代码
git status
git add .
git commit -m "Release RongCloud SourceCode Version ${Version}"
git push origin main -v

##  打 tag
TAGS=`git tag`

if [[ "${TAGS[*]}" =~ $Version ]]; then
    git tag -d $Version
    git push origin --delete tag $Version
fi

git tag -a $Version -m $Version
git push origin $Version

