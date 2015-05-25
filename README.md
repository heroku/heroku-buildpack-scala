Heroku Buildpack for Scala [![Build Status](https://travis-ci.org/heroku/heroku-buildpack-scala.svg?branch=master)](https://travis-ci.org/heroku/heroku-buildpack-scala)
=========================

This This is the official [Heroku buildpack](http://devcenter.heroku.com/articles/buildpacks) for Scala apps.
It uses [sbt](https://github.com/harrah/xsbt/) 0.11.0+.

How it works
-----

The buildpack will detect your app as Scala if it has a `project/build.properties` file and either a `.sbt` or `.scala` based build config (for example, a `build.sbt` file).  It vendors a version of sbt into your slug (if you are not using sbt-native-packager, it also includes your popluated `.ivy/cache` in the slug).  The `.ivy2` directory will be cached between builds to allow for faster build times.

It is strongly recommended that you use sbt-native-packager with this buildpack instead of sbt-start-script. The latter is deprecated, and will result in exessively large slug sizes. 

Documentation
------------

For more information about using Scala and buildpacks on Heroku, see these articles:

*  [Heroku's Scala Support](https://devcenter.heroku.com/articles/scala-support)
*  [Play Documentation: Deploying to Heroku](https://playframework.com/documentation/2.3.x/ProductionHeroku)
*  [Customizing the JDK](https://devcenter.heroku.com/articles/customizing-the-jdk)
*  [Running a Remote sbt Console for a Scala or Play Application ](https://devcenter.heroku.com/articles/running-a-remote-sbt-console-for-a-scala-or-play-application)
*  [Using Node.js to perform JavaScript optimization for Play and Scala applications](https://devcenter.heroku.com/articles/using-node-js-to-perform-javascript-optimization-for-play-and-scala-applications)
*  [Reducing the Slug Size of Play 2.x Applications](https://devcenter.heroku.com/articles/reducing-the-slug-size-of-play-2-x-applications)

Examples
------------

There are a number of example applications that demonstrate various ways of configuring a project for use on Heroku. Here are a few:

*  [Play Database seed](https://github.com/mkbehbehani/play-heroku-seed)
*  [Play Silhouette Angular seed](https://github.com/mohiva/play-silhouette-angular-seed)
*  [Minimal sbt example](https://github.com/kissaten/sbt-minimal-scala-sample)
*  [Lift example](https://github.com/kissaten/lift-2.5-sample)

Customizing
-----------

This buildpack uses [sbt-extras](https://github.com/paulp/sbt-extras) to run sbt.
In this way, the execution of sbt can be customized either by setting
the SBT_OPTS config variable, or by creating a `.sbtopts` file in the
root directory of your project. When passing options to the underlying
sbt JVM, you must prefix them with `-J`. Thus, setting stack size for
the compile process would look like this:

```
$ heroku config:set SBT_OPTS="-J-Xss4m"
```

Clean builds
------------

In some cases, builds need to clean artifacts before compiling. If a clean build is necessary, configure builds to perform clean by setting `SBT_CLEAN=true`:

```sh-session
$ heroku config:set SBT_CLEAN=true
Setting config vars and restarting example-app... done, v17
SBT_CLEAN: true
```

All subsequent deploys will use the clean task. To remove the clean task, unset `SBT_CLEAN`:

```sh-session
$ heroku config:unset SBT_CLEAN
Unsetting SBT_CLEAN and restarting example-app... done, v18
```

Development
-------

To make changes to this buildpack, fork it on Github. Push up changes to your fork, then create a new Heroku app to test it, or configure an existing app to use your buildpack:

```
# Create a new Heroku app that uses your buildpack
heroku create --buildpack <your-github-url>

# Configure an existing Heroku app to use your buildpack
heroku buildpacks:set <your-github-url>

# You can also use a git branch!
heroku buildpacks:set <your-github-url>#your-branch
```

License
-------

Licensed under the MIT License. See LICENSE file.
