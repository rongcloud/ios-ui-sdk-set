#!/bin/sh

trap exit ERR

Private_Pods_Demo_Git=$1

git reset --hard origin/main
git checkout -f main
git pull

##  打 tag
TAGS=`git tag`

if [[ "${TAGS[*]}" =~ $Version ]]; then
	git tag -d $Version
	git push origin --delete tag $Version
fi

git tag -a $Version -m $Version
git push origin $Version

echo "******** 推送私有 pods 仓库开始 ********"
# 私有 pods 仓库
pod repo push spec RongCloudOpenSource.podspec --verbose --allow-warnings
echo "******** 推送私有 pods 仓库结束 ********"

echo "******** 验证私有 pods 仓库开始 ********"
# demo 测试私有 pods
PodsDemoPath="ios_privatepodsdemo/build.sh"
# 检查文件是否存在
if [ ! -e "$PodsDemoPath" ]; then
   git clone $Private_Pods_Demo_Git
fi

cd ios_privatepodsdemo
sh build.sh sourceCode
cd ..
echo "******** 验证私有 pods 仓库结束 ********"

pod trunk push --use-libraries --allow-warnings --verbose
