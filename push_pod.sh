#!/bin/sh

trap exit ERR

Private_Pods_Demo_Git=$1
Only_Private_Verify=$2

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

echo "******** 私有 pods 仓库操作开始 ********"
# 私有 pods 仓库
PodsDemoPath="ios_privatepodsdemo/build.sh"
# 检查文件是否存在
if [ ! -e "$PodsDemoPath" ]; then
   git clone $Private_Pods_Demo_Git
fi

cd ios_privatepodsdemo
sh build.sh $Version sourcecode
cd ..
echo "******** 私有 pods 仓库操作结束 ********"

if [ "$Only_Private_Verify" != "true" ]; then
    pod trunk push --use-libraries --allow-warnings --verbose
fi
