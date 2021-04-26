#!/bin/sh

git checkout main
git reset --hard origin/main
git clean -dfx
git pull

sed -i ""  -e 's/[0-9]\.[0-9]\{1,2\}\.[0-9]\{1,2\}/'"$Version"'/' RongCloudOpenSource.podspec

pod trunk push --use-libraries --allow-warnings --verbose
