#!/usr/bin/env bash

handle_sbt_errors() {
  local log_file="$1"

  local header="Failed to run sbt!"

  if grep -qi 'Not a valid key: stage' "$log_file"; then
    error "${header}
It looks like your build.sbt does not have a valid 'stage' task.
Please read our Dev Center article for information on how to create one:
https://devcenter.heroku.com/articles/scala-support#build-behavior
If you continue to have problems, please submit a ticket so we can help:
http://help.heroku.com

Thanks,
Heroku"
  else
    error "${header}
We're sorry this build is failing! If you can't find the issue in application
code, please submit a ticket so we can help: https://help.heroku.com
You can also try reverting to the previous version of the buildpack by running:
$ heroku buildpacks:set https://github.com/heroku/heroku-buildpack-scala#previous-version

Thanks,
Heroku"
  fi
}
