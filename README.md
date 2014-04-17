Heroku buildpack: Scala
=========================

This is a [Heroku buildpack](http://devcenter.heroku.com/articles/buildpacks) for Scala apps.
It uses [sbt](https://github.com/harrah/xsbt/) 0.11.0+.

Usage
-----

Example usage:

    $ ls
    Procfile build.sbt project src

    $ heroku create --buildpack https://github.com/heroku/heroku-buildpack-scala.git

    $ git push heroku master
    ...
    -----> Heroku receiving push
    -----> Scala app detected
    -----> Building app with sbt
    -----> Running: sbt clean compile stage

The buildpack will detect your app as Scala if it has the project/build.properties and either .sbt or .scala based build config.  It vendors a version of sbt into your slug.  The .ivy2 directory will be cached between builds to allow for faster build times, but is not included into the slug.

License
-------

Licensed under the MIT License. See LICENSE file.
