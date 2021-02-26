#!/bin/sh

git checkout dev
git reset --hard origin/dev
git clean -dfx
git pull

pod trunk push --verbose --allow-warnings