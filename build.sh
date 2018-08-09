#!/bin/bash

# usage: ./deploy.sh
# license: public domain

#!/usr/bin/env bash

AWS_ACCOUNT_ID=953185573346
NAME=att-dp-static-host
REGION=us-west-2

# checks if branch has something pending
function parse_git_dirty() {
  git diff --quiet --ignore-submodules HEAD 2>/dev/null; [ $? -eq 1 ] && echo "*"
}

# gets the current git branch
function parse_git_branch() {
  git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e "s/* \(.*\)/\1$(parse_git_dirty)/"
}

# get last commit hash prepended with - (i.e. -7654dc9d86d9e171378d3858f9fc66bcbce953bf)
function parse_git_hash() {
  git rev-parse HEAD 2> /dev/null | sed "s/\(.*\)/-\1/"
}

# DEMO
GIT_VERSION=$(parse_git_branch)$(parse_git_hash)

aws configure set default.region $REGION

# Authenticate against our Docker registry
eval $(aws ecr get-login --no-include-email)

# Build and push the image
docker build -t $NAME:$GIT_VERSION .
docker tag $NAME:$GIT_VERSION $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$NAME:$GIT_VERSION
docker push $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$NAME:$GIT_VERSION
