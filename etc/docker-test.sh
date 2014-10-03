#!/bin/bash

docker images | grep heroku/testrunner > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "You must first create the Docker image 'heroku/testrunner' from the heroku-buildpack-testrunner project"
fi

if [ "Darwin" == `uname` ]; then
  VBoxManage showvminfo  boot2docker-vm | grep "Name: 'home', Host path: '/Users'" > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "You probably need to share your /Users directory with the Docker VM!"
    echo "  > boot2docker stop"
    echo "  > VBoxManage sharedfolder add boot2docker-vm -name home -hostpath /Users"
    echo "  > boot2docker start"
    echo ""
    echo "See this article for more info: https://medium.com/boot2docker-lightweight-linux-for-docker/boot2docker-together-with-virtualbox-guest-additions-da1e3ab2465c"
    exit 1
  fi
fi

DIR=$(cd $(dirname $0)/..; pwd)

docker run -it -v $DIR:/app/buildpack:ro heroku/testrunner
