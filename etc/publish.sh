#!/bin/bash

set -e

BP_NAME="scala"

if [ ! -z "$1" ]; then
  pushd . > /dev/null 2>&1
  cd /tmp
  rm -rf heroku-buildpack-$BP_NAME
  git clone git@github.com:heroku/heroku-buildpack-$BP_NAME.git
  cd heroku-buildpack-$BP_NAME
  git checkout master
  headHash=$(git rev-parse HEAD)

  find . ! -name '.' ! -name '..' ! -name 'bin' ! -name 'opt' \
         ! -name 'lib' -maxdepth 1 -print0 | xargs -0 rm -rf --
  heroku buildkits:publish $1/$BP_NAME

  if [ "$1" = "heroku" ]; then
    newTag=$(heroku buildkits:revisions heroku/$BP_NAME | sed -n 2p | grep -o -e "v\d*")
  fi

  popd > /dev/null 2>&1
  echo "Cleaning up..."
  rm -rf /tmp/heroku-buildpack-$BP_NAME

  if [ "$1" = "heroku" ]; then
    if [ "$headHash" = "$(git rev-parse HEAD)" ]; then
      echo "Tagging commit $headHash with $newTag... "
      git tag $newTag
      echo "Updating previous-version tag"
      git tag -d previous-version
      git push origin :previous-version
      git tag previous-version latest-version
      echo "Updating latest-version tag"
      git tag -d latest-version
      git push origin :latest-version
      git tag latest-version
      git push --tags
    fi
  fi

  echo "Done."
else
  echo "You must provide a buildkit organization as an argument!"
  exit 1
fi
