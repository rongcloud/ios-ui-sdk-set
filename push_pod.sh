#!/bin/sh

git checkout main
git reset --hard origin/main
git clean -dfx
git pull

pod trunk push --verbose --allow-warnings