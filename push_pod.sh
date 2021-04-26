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


sed -i ""  -e 's/[0-9]\.[0-9]\{1,2\}\.[0-9]\{1,2\}/'"$Version"'/' RongCloudOpenSource.podspec

pod trunk push --use-libraries --allow-warnings --verbose
