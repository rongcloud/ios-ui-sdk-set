#!/bin/sh

git checkout main
git reset --hard origin/main
git clean -dfx
git pull

##  打 tag
TAGS=`git tag`

if [[ "${TAGS[*]}" =~ $Version ]]; then
	git tag -d $Version
	git push origin --delete tag $Version
fi

git tag -a $Version -m $Version
git push origin $Version


sed -i ""  -e 's/pod_ver/'"$Version"'/' RongCloudOpenSource.podspec
sed -i ""  -e 's/sdk_ver/'"$SDK_Version"'/' RongCloudOpenSource.podspec

pod trunk push --use-libraries --allow-warnings --verbose
