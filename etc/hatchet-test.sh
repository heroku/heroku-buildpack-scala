#!/usr/bin/env bash

if [ "$TRAVIS_PULL_REQUEST" != "false" ]; then
  echo "Skipping Hatchet tests on Pull Request."
else
  gem install bundler
  bundle install

  bundle exec hatchet install &&
  HATCHET_RETRIES=3 \
  HATCHET_DEPLOY_STRATEGY=git \
  HATCHET_BUILDPACK_BASE="https://github.com/heroku/heroku-buildpack-scala.git" \
  HATCHET_BUILDPACK_BRANCH=$(git name-rev HEAD 2> /dev/null | sed 's#HEAD\ \(.*\)#\1#') \
  bundle exec rspec spec/
fi
