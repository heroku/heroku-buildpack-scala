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
