# Changelog

## [Unreleased]


## [v99] - 2025-09-10

* Add metrics infrastructure and collection ([#259](https://github.com/heroku/heroku-buildpack-scala/pull/259))
* Remove heroku-20 support ([#252](https://github.com/heroku/heroku-buildpack-scala/pull/252))

## [v98] - 2024-02-14

* Fix Play Framework detection for Play >= `3.0.0`. ([#240](https://github.com/heroku/heroku-buildpack-scala/pull/240))

## [v97] - 2024-02-07

* Remove heroku-18 support. ([#226](https://github.com/heroku/heroku-buildpack-scala/pull/226))
* Fix deprecation warnings when using sbt `>= 1.5`. ([#232](https://github.com/heroku/heroku-buildpack-scala/pull/232))
* Support for sbt `1.0.x` has been removed. ([#232](https://github.com/heroku/heroku-buildpack-scala/pull/232))

## [v96] - 2022-09-30

* Add support for the `DISABLE_DEPENDENCY_CLASSPATH_LOG` environment variable to disable the dependency classpath log. 

## [v95] - 2022-09-26

* Only provision Heroku Postgres if the app declares a dependency on one of the following postgres drivers:
    - [Official Postgres JDBC Driver](https://jdbc.postgresql.org/)
    - [PGJDBC-NG](https://impossibl.github.io/pgjdbc-ng/)
    - [Skunk](https://tpolecat.github.io/skunk/)
    - [postgresql-async](https://github.com/postgresql-async/postgresql-async)
    - [quill-ndbc-postgres](https://getquill.io/#docs)

## [v94] - 2022-06-14

* Adjust curl retry and connection timeout handling
* Vendor buildpack-stdlib rather than downloading it at build time
* Switch to the recommended regional S3 domain instead of the global one

## [v93] - 2022-06-07

* Add heroku-22 support

## [v92] - 2022-02-09

* Update sbt-extras, support for sbt >= 1.6.2

## [v91] - 2021-10-14

* Download the JVM Common buildpack from the buildpack registry, rather than the legacy `codon-buildpacks` S3 bucket.
* Remove heroku-16 support

## [v90] - 2021-03-09

* Update sbt-extras, support for sbt >= 1.4.8

## v89

* Enable heroku-20 testing

## v88

* Update sbt-extras
* Update tests

## v87

* Added ability to run as a CNB with a shim

## v86

* Clean sbt cache dir from slug

## v85

* Pass cache to JVM install to cache system.properties file

## v84

* Export sbt command for use by subsequent buildpacks

## v83

* Ensure bash when running sbt-wrapper

## v82

* Changed location of JVM common buildpack

## v80

* Clean up coursier cache directory after sbt build

## v79

* Fixed a bug related to sbt 1.0 and the HerokuBuildpackPlugin

## v69

* Fixed a bug in system.properties detection

## v68

* Removed default JAVA_OPTS from bin/release
* Added support for sbt.project config

## v66

* Added support for SBT 0.13.11

## v63

* Added detection for specific failure cases and advised solutions in message.

## v62

* Updated sbt cache primer to include Play 2.4.3

## v61

* Added SBT_PRE_TASKS config var support
* Upgrade SBT launcher version to 0.13.9

## v60

* Updated sbt cache primer to include Play 2.4.2

## v59

* Remove play-fork-run.sbt if it exists to workaround Activator bug.

## v57

* Added support for Play 2.4

## v56

* Upgrade sbt cache packages

## v54

* Upgrade default sbt version to 0.13.8

## v52

* Use sbt-extras to manage sbt versions and options

## v49

*  Upgrade to sbt 0.13.7 launcher
*  Allow for customized jvm-common package

[unreleased]: https://github.com/heroku/heroku-buildpack-scala/compare/v99...main
[v99]: https://github.com/heroku/heroku-buildpack-scala/compare/v98...v99
[v98]: https://github.com/heroku/heroku-buildpack-scala/compare/v97...v98
[v97]: https://github.com/heroku/heroku-buildpack-scala/compare/v96...v97
[v96]: https://github.com/heroku/heroku-buildpack-scala/compare/v95...v96
[v95]: https://github.com/heroku/heroku-buildpack-scala/compare/v94...v95
[v94]: https://github.com/heroku/heroku-buildpack-scala/compare/v93...v94
[v93]: https://github.com/heroku/heroku-buildpack-scala/compare/v92...v93
[v92]: https://github.com/heroku/heroku-buildpack-scala/compare/v91...v92
[v91]: https://github.com/heroku/heroku-buildpack-scala/compare/v90...v91
[v90]: https://github.com/heroku/heroku-buildpack-scala/compare/v89...v90
