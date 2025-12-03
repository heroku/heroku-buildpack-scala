# Changelog

## [Unreleased]

* Sanitize `SBT_OPTS` by removing `-J` prefix from arguments. ([#309](https://github.com/heroku/heroku-buildpack-scala/pull/309))
* Fail builds early for `sbt` versions older than `0.13.18`. These versions have shown very frequent and hard to debug issues with user builds. Builds now fail immediately with a clear error message and instructions. ([#307](https://github.com/heroku/heroku-buildpack-scala/pull/307))


## [v104] - 2025-12-02

* Improve `SBT_PROJECT` handling for multi-project builds. ([#299](https://github.com/heroku/heroku-buildpack-scala/pull/299))
* Deprecate `SBT_PRE_TASKS` configuration option. ([#299](https://github.com/heroku/heroku-buildpack-scala/pull/299))
* Improve build failure error messages. ([#298](https://github.com/heroku/heroku-buildpack-scala/pull/298))
* Fix `sbt` launcher output indentation. ([#296](https://github.com/heroku/heroku-buildpack-scala/pull/296))
* Improve plugin detection using `sbt about` instead of parsing `project/plugins.sbt` files. ([#294](https://github.com/heroku/heroku-buildpack-scala/pull/294))
* Suppress `sbt` batch mode warning. ([#293](https://github.com/heroku/heroku-buildpack-scala/pull/293))
* Replace `sbt-extras` with direct `sbt` launcher installation. ([#291](https://github.com/heroku/heroku-buildpack-scala/pull/291))
* Remove build directory symlinking. Modern `sbt` versions no longer require a stable build path for caching. ([#290](https://github.com/heroku/heroku-buildpack-scala/pull/290))

## [v103] - 2025-10-27

* Add error for unsupported `sbt` `2.x` versions. ([#281](https://github.com/heroku/heroku-buildpack-scala/pull/281))
* Add warning for unsupported `sbt` `0.x` versions. ([#281](https://github.com/heroku/heroku-buildpack-scala/pull/281))
* Remove automatic deletion of `project/play-fork-run.sbt` files. Maintainers of legacy apps can consult the PR description for background and how to fix their project in the unlikely case it's necessary. ([#280](https://github.com/heroku/heroku-buildpack-scala/pull/280))
* Deprecate Scala buildpack configuration via `system.properties`. A warning is now shown when Scala buildpack configuration properties (like `sbt.clean`, `sbt.project`, etc.) are detected in `system.properties`. Use environment variables instead. This does not affect `java.runtime.version` which remains supported. ([#279](https://github.com/heroku/heroku-buildpack-scala/pull/279))
* Remove partial CNB functionality. ([#276](https://github.com/heroku/heroku-buildpack-scala/pull/276))
* Remove Ivy cache priming feature. ([#275](https://github.com/heroku/heroku-buildpack-scala/pull/275))
* Improve `bin/detect` error messages when `sbt` project files are missing. ([#274](https://github.com/heroku/heroku-buildpack-scala/pull/274))

## [v102] - 2025-10-21

* Fix buildpack not failing when `sbt` compilation fails. ([#272](https://github.com/heroku/heroku-buildpack-scala/pull/272))
* Fix `PATH` and `GEM_PATH` rewriting logic when build directory is moved. ([#269](https://github.com/heroku/heroku-buildpack-scala/pull/269))

## [v100] - 2025-09-30

* Code improvements, no changes for users. ([#262](https://github.com/heroku/heroku-buildpack-scala/pull/262))

## [v99] - 2025-09-10

* Add metrics infrastructure and collection. ([#259](https://github.com/heroku/heroku-buildpack-scala/pull/259))
* Remove `heroku-20` support. ([#252](https://github.com/heroku/heroku-buildpack-scala/pull/252))

## [v98] - 2024-02-14

* Fix Play Framework detection for Play >= `3.0.0`. ([#240](https://github.com/heroku/heroku-buildpack-scala/pull/240))

## [v97] - 2024-02-07

* Remove `heroku-18` support. ([#226](https://github.com/heroku/heroku-buildpack-scala/pull/226))
* Fix deprecation warnings when using `sbt` >= `1.5`. ([#232](https://github.com/heroku/heroku-buildpack-scala/pull/232))
* Support for `sbt` `1.0.x` has been removed. ([#232](https://github.com/heroku/heroku-buildpack-scala/pull/232))

## [v96] - 2022-09-30

* Add support for the `DISABLE_DEPENDENCY_CLASSPATH_LOG` environment variable to disable the dependency classpath log. ([#210](https://github.com/heroku/heroku-buildpack-scala/pull/210))

## [v95] - 2022-09-26

* Only provision Heroku Postgres if the app declares a dependency on one of the following postgres drivers: ([#207](https://github.com/heroku/heroku-buildpack-scala/pull/207))
    - [Official Postgres JDBC Driver](https://jdbc.postgresql.org/)
    - [PGJDBC-NG](https://impossibl.github.io/pgjdbc-ng/)
    - [Skunk](https://tpolecat.github.io/skunk/)
    - [postgresql-async](https://github.com/postgresql-async/postgresql-async)
    - [quill-ndbc-postgres](https://getquill.io/#docs)

## [v94] - 2022-06-14

* Adjust `curl` retry and connection timeout handling. ([#204](https://github.com/heroku/heroku-buildpack-scala/pull/204))
* Vendor `buildpack-stdlib` rather than downloading it at build time. ([#202](https://github.com/heroku/heroku-buildpack-scala/pull/202))
* Switch to the recommended regional S3 domain instead of the global one. ([#203](https://github.com/heroku/heroku-buildpack-scala/pull/203))

## [v93] - 2022-06-07

* Add `heroku-22` support. ([#200](https://github.com/heroku/heroku-buildpack-scala/pull/200))

## [v92] - 2022-02-09

* Update `sbt-extras`, support for `sbt` >= `1.6.2`. ([#197](https://github.com/heroku/heroku-buildpack-scala/pull/197))

## [v91] - 2021-10-14

* Download the JVM Common buildpack from the buildpack registry, rather than the legacy `codon-buildpacks` S3 bucket. ([#191](https://github.com/heroku/heroku-buildpack-scala/pull/191))
* Remove `heroku-16` support. ([#187](https://github.com/heroku/heroku-buildpack-scala/pull/187))

## [v90] - 2021-03-09

* Update `sbt-extras`, support for `sbt` >= `1.4.8`. ([#185](https://github.com/heroku/heroku-buildpack-scala/pull/185))

## [v89] - 2021-02-23

* Enable `heroku-20` testing. ([#172](https://github.com/heroku/heroku-buildpack-scala/pull/172))

## [v88] - 2020-10-12

* Update `sbt-extras`.
* Update tests.

## [v87] - 2020-01-15

* Add ability to run as a CNB with a shim. ([#142](https://github.com/heroku/heroku-buildpack-scala/pull/142))

## [v86] - 2019-10-03

* Clean `sbt` cache dir from slug. ([#141](https://github.com/heroku/heroku-buildpack-scala/pull/141))

## [v85] - 2019-03-18

* Pass cache to JVM install to cache `system.properties` file. ([#137](https://github.com/heroku/heroku-buildpack-scala/pull/137))

## [v84] - 2019-02-04

* Export `sbt` command for use by subsequent buildpacks. ([#135](https://github.com/heroku/heroku-buildpack-scala/pull/135))

## [v83] - 2018-11-01

* Ensure `bash` when running `sbt-wrapper`. ([#133](https://github.com/heroku/heroku-buildpack-scala/pull/133))

## [v82] - 2018-06-14

* Change location of JVM common buildpack. ([#130](https://github.com/heroku/heroku-buildpack-scala/pull/130))

## [v80] - 2018-04-30

* Clean up `coursier` cache directory after `sbt` build. ([#129](https://github.com/heroku/heroku-buildpack-scala/pull/129))

## [v79] - 2017-10-11

* Fix bug related to `sbt` `1.0` and the `HerokuBuildpackPlugin`. ([#126](https://github.com/heroku/heroku-buildpack-scala/pull/126))

## [v69] - 2016-04-13

* Fix bug in `system.properties` detection.

## [v68] - 2016-04-07

* Remove default `JAVA_OPTS` from `bin/release`.
* Add support for `sbt.project` config.

## [v66] - 2016-02-23

* Add support for SBT `0.13.11`.

## [v63] - 2015-10-12

* Add detection for specific failure cases and advised solutions in message.

## [v62] - 2015-09-21

* Update `sbt` cache primer to include Play `2.4.3`.

## [v61] - 2015-09-02

* Add `SBT_PRE_TASKS` config var support.
* Upgrade SBT launcher version to `0.13.9`.

## [v60] - 2015-07-22

* Update `sbt` cache primer to include Play `2.4.2`.

## [v59] - 2015-07-13

* Remove `play-fork-run.sbt` if it exists to workaround Activator bug.

## [v57] - 2015-05-28

* Add support for Play `2.4`.

## [v56] - 2015-05-18

* Upgrade `sbt` cache packages.

## [v54] - 2015-03-23

* Upgrade default `sbt` version to `0.13.8`.

## [v52] - 2015-03-11

* Use `sbt-extras` to manage `sbt` versions and options.

## [v49] - 2015-01-15

* Upgrade to `sbt` `0.13.7` launcher.
* Allow for customized jvm-common package.

[unreleased]: https://github.com/heroku/heroku-buildpack-scala/compare/v104...main
[v104]: https://github.com/heroku/heroku-buildpack-scala/compare/v103...v104
[v103]: https://github.com/heroku/heroku-buildpack-scala/compare/v102...v103
[v102]: https://github.com/heroku/heroku-buildpack-scala/compare/v101...v102
[v100]: https://github.com/heroku/heroku-buildpack-scala/compare/v99...v100
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
[v89]: https://github.com/heroku/heroku-buildpack-scala/compare/v88...v89
[v88]: https://github.com/heroku/heroku-buildpack-scala/compare/v87...v88
[v87]: https://github.com/heroku/heroku-buildpack-scala/compare/v86...v87
[v86]: https://github.com/heroku/heroku-buildpack-scala/compare/v85...v86
[v85]: https://github.com/heroku/heroku-buildpack-scala/compare/v84...v85
[v84]: https://github.com/heroku/heroku-buildpack-scala/compare/v83...v84
[v83]: https://github.com/heroku/heroku-buildpack-scala/compare/v82...v83
[v82]: https://github.com/heroku/heroku-buildpack-scala/compare/v81...v82
[v80]: https://github.com/heroku/heroku-buildpack-scala/compare/v79...v80
[v79]: https://github.com/heroku/heroku-buildpack-scala/compare/v78...v79
[v69]: https://github.com/heroku/heroku-buildpack-scala/compare/v68...v69
[v68]: https://github.com/heroku/heroku-buildpack-scala/compare/v67...v68
[v66]: https://github.com/heroku/heroku-buildpack-scala/compare/v65...v66
[v63]: https://github.com/heroku/heroku-buildpack-scala/compare/v62...v63
[v62]: https://github.com/heroku/heroku-buildpack-scala/compare/v61...v62
[v61]: https://github.com/heroku/heroku-buildpack-scala/compare/v60...v61
[v60]: https://github.com/heroku/heroku-buildpack-scala/compare/v59...v60
[v59]: https://github.com/heroku/heroku-buildpack-scala/compare/v58...v59
[v57]: https://github.com/heroku/heroku-buildpack-scala/compare/v56...v57
[v56]: https://github.com/heroku/heroku-buildpack-scala/compare/v55...v56
[v54]: https://github.com/heroku/heroku-buildpack-scala/compare/v53...v54
[v52]: https://github.com/heroku/heroku-buildpack-scala/compare/v51...v52
[v49]: https://github.com/heroku/heroku-buildpack-scala/compare/v48...v49
