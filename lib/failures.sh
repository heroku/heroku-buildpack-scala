#!/usr/bin/env bash

handle_sbt_errors() {
  local log_file="$1"

  local header="Failed to run sbt!"

  local previousVersion="You can also try reverting to the previous version of the buildpack by running:
$ heroku buildpacks:set https://github.com/heroku/heroku-buildpack-scala#previous-version"

  local footer="Thanks,
Heroku"

  if grep -qi 'Not a valid key: stage' "$log_file"; then
    error "${header}
It looks like your build.sbt does not have a valid 'stage' task.
Please read our Dev Center article for information on how to create one:
https://devcenter.heroku.com/articles/scala-support#build-behavior
If you continue to have problems, please submit a ticket so we can help:
http://help.heroku.com

${footer}"
  elif grep -qi 'is already defined as object' "$log_file"; then
    error "${header}
We're sorry this build is failing. It looks like you may need to run a
clean build to remove any stale SBT caches. You can do this by setting
a configuration variable like this:

    $ heroku config:set SBT_CLEAN=true

Then deploy you application with 'git push' again. If the build succeeds
you can remove the variable by running this command

    $ heroku config:unset SBT_CLEAN

If this does not resolve the problem, please submit a ticket so we
can help: https://help.heroku.com
${previousVersion}

${footer}"
  else
    error "${header}
We're sorry this build is failing. If you can't find the issue in application
code, please submit a ticket so we can help: https://help.heroku.com
${previousVersion}

${footer}"
  fi
}
