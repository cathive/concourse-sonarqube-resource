# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2018-02-07

### Fixed

- Parameters that contain whitespace characters no longer fail the `out` action.
  [(#6)(https://github.com/cathive/concourse-sonarqube-resource/issues/6)]

### Added

- Support for `params.tests`.
  [(#7)(https://github.com/cathive/concourse-sonarqube-resource/issues/7)]

- Support for `params.branch_name` and `params.branch_target`.
  Require the [Branch Plugin](https://docs.sonarqube.org/display/PLUG/Branch+Plugin) or
  SonarCloud.

### Changed

- `params.sources` must now be specified as list instead of comma-separated strings

### Removed

- `params.branch` and `params.analysis_mode` are no longer supported.
  (New SonarQube versions handle short-lived branches in a different way)
  Use `params.branch_name` and `params.branch_target` instead if you use the
  Branch plugin.

## [0.0.32] - 2018-01-31

### Fixed

- Support old SonarQube servers that don't report the server version in report-task.txt (Just report "unknown" as server version) [(#11)(https://github.com/cathive/concourse-sonarqube-resource/issues/11)]

## [0.0.31] - 2018-01-23

### Fixed

- Support old SonarQube servers that don't report the server version in report-task.txt (under certain conditions, this fix will not work though) [(#11)(https://github.com/cathive/concourse-sonarqube-resource/issues/11)]

## [0.0.30] - 2018-01-18

### Added

- Support for any additional properties that might need to be passed to the sonar-scanner.

### Fixed

- Updated the documentation to make clear how a quality gate can be used to break the build.
  [(#9)](https://github.com/cathive/concourse-sonarqube-resource/issues/9)

## [0.0.20] - 2018-01-04

### Added

- Support for SonarQube/SonarCloud organizations. [(#8)](https://github.com/cathive/concourse-sonarqube-resource/issues/8)
