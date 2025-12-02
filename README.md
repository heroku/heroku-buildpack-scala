![](https://raw.githubusercontent.com/heroku/buildpacks/refs/heads/main/assets/images/buildpack-banner-scala.jpg)

# Heroku Buildpack: Scala (sbt) [![CI](https://github.com/heroku/heroku-buildpack-scala/actions/workflows/ci.yml/badge.svg)](https://github.com/heroku/heroku-buildpack-scala/actions/workflows/ci.yml)

This is the official [Heroku buildpack](https://devcenter.heroku.com/articles/buildpacks) for apps that use [sbt](https://www.scala-sbt.org/) as their build tool. It's primarily used to build [Scala](https://www.scala-lang.org/) applications, but it can also build applications written in other JVM languages (such as [Play Framework](https://www.playframework.com/) apps written in Java).

If you're using a different JVM build tool, use the appropriate buildpack:
* [Java buildpack](https://github.com/heroku/heroku-buildpack-java) for [Maven](https://maven.apache.org/) projects
* [Gradle buildpack](https://github.com/heroku/heroku-buildpack-gradle) for [Gradle](https://gradle.org/) projects
* [Clojure buildpack](https://github.com/heroku/heroku-buildpack-clojure) for [Leiningen](https://leiningen.org/) projects

## Table of Contents

- [Supported sbt Versions](#supported-sbt-versions)
- [Getting Started](#getting-started)
- [Application Requirements](#application-requirements)
- [Configuration](#configuration)
  - [OpenJDK Version](#openjdk-version)
  - [sbt Version](#sbt-version)
  - [Buildpack Configuration](#buildpack-configuration)
- [Documentation](#documentation)

## Supported sbt Versions

This buildpack officially supports sbt `1.x`. Best-effort support is available for apps using sbt `0.13.18`. sbt `2.x` support will be added after its release.

## Getting Started

See the [Getting Started on Heroku with Scala](https://devcenter.heroku.com/articles/getting-started-with-scala) tutorial.

## Application Requirements

Your app requires at least one `.sbt` file and a `project/build.properties` file in the root directory. The `project/build.properties` file must define the `sbt.version` property.

The buildpack uses the `stage` sbt task to build your application. The easiest way to provide this task is with [`sbt-native-packager`](https://github.com/sbt/sbt-native-packager), which includes it by default.

## Configuration

### OpenJDK Version

Specify an OpenJDK version by creating a `system.properties` file in the root of your project directory and setting the `java.runtime.version` property. See the [Java Support article](https://devcenter.heroku.com/articles/java-support#supported-java-versions) for available versions and configuration instructions.

### sbt Version

The buildpack uses the `sbt.version` property in your `project/build.properties` file to determine which sbt version to use. Update this property to change the sbt version.

### Buildpack Configuration

Configure the buildpack by setting environment variables:

| Environment Variable | Description | Default |
|---------------------|-------------|---------|
| `SBT_TASKS` | sbt tasks to execute | `compile stage` |
| `SBT_OPTS` | JVM options for sbt execution | (none) |
| `SBT_CLEAN` | Run `clean` task before build | `false` |
| `SBT_PROJECT` | For multi-project builds, specifies which project to build | (none) |
| `SBT_AT_RUNTIME` | Make sbt available at runtime | `true` |
| `KEEP_SBT_CACHE` | Prevent removal of compilation artifacts from slug | `false` |

## Documentation

For more information about using Scala on Heroku, see the [Scala Support](https://devcenter.heroku.com/categories/scala-support) documentation on Dev Center.