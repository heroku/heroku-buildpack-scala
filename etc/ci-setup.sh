#!/usr/bin/env bash

[ "$CI" != "true" ] && echo "Not running on CI!" && exit 1

curl --silent https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/shunit2/shunit2-2.1.6.tgz | tar xz -C /tmp/
git clone https://github.com/heroku/heroku-buildpack-testrunner.git /tmp/testrunner

git config --global user.email ${HEROKU_API_USER:-"buildpack@example.com"}
git config --global user.name 'BuildpackTester'

cat <<EOF >> ~/.ssh/config
Host heroku.com
    StrictHostKeyChecking no
    CheckHostIP no
    UserKnownHostsFile=/dev/null
Host github.com
    StrictHostKeyChecking no
EOF

cat <<EOF >> ~/.netrc
machine git.heroku.com
  login ${HEROKU_API_USER:-"buildpack@example.com"}
  password ${HEROKU_API_KEY:-"password"}
EOF

sudo apt-get -qq update
sudo apt-get install software-properties-common -y
curl --fail --retry 3 --retry-delay 1 --connect-timeout 3 --max-time 30 https://cli-assets.heroku.com/install-ubuntu.sh | sh

yes | heroku keys:add
