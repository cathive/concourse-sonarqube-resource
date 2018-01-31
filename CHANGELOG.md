# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

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
