#!/bin/bash

if [ ! -z "$1" ]; then
  pushd . > /dev/null 2>&1
  cd /tmp &&
  git clone git@github.com:heroku/heroku-buildpack-scala.git &&
  cd heroku-buildpack-scala &&
  git checkout master &&
  find . ! -name 'bin' ! -name 'opt' -maxdepth 1 -delete &&
  heroku buildpacks:publish $1/scala
  popd > /dev/null 2>&1
  echo "Cleaning up..."
  rm -rf /tmp/heroku-buildpack-scala
  echo "Done."
else
  echo "You must provide a buildkit organization as an argument!"
  exit 1
fi
