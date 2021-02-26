#!/bin/bash

#  Created by qixinbing on 2021/2/26.
#  Copyright (c) 2021 RongCloud. All rights reserved.

#Version=5.0.0
#Release_Node=113

## 1. 更新 git 仓库
git checkout dev
git reset --hard origin/dev
git clean -dfx
git pull

## 2. 更新所有的代码
function update_sdk(){
	src_name=$1
	target_name=$2
	cp /var/lib/jenkins/jobs/iOS-SDK-Release/builds/{Release_Node}/archive/output/${src_name}_SourceCode_*.zip ./
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
update_sdk RongCallKit CallKit

## 3. 更新 podspec 版本
sed -i ""  -e 's/[0-9]\.[0-9]\{1,2\}\.[0-9]\{1,2\}/'"$Version"'/' RongCloudOpenSource.podspec

## 4. 提交代码
git status
git add .
git commit -m "Release RongCloud SourceCode Version ${Version}"
git push origin dev -v

## 5. 打 tag
TAGS=`git tag`

if [[ "${TAGS[*]}" =~ $Version ]]; then
	git tag -d $Version
	git push origin --delete tag $Version
fi

git tag -a $Version -m $Version
git push origin $Version
