#!/bin/sh

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

pod trunk push --use-libraries --allow-warnings --verbose
