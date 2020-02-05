# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [0.11.2] - 2020-02-05

### Fixed

- JAVA_HOME was not correctly linked and rendered the `cli` variant of the sonar-scanner
  unusable. [#50](https://github.com/cathive/concourse-sonarqube-resource/issues/50) 

## [0.11.1] - 2020-01-24 [YANKED]

### Fixed

- Base container image has been downgraded to `openjdk:11.0.6-slim`
  SonarQube scanners as of now only support Java 8 and Java 11
  according to the [documentation](https://docs.sonarqube.org/latest/requirements/requirements/).
  Some plugins don't support newer Java runtimes which breaks all
  functionality of this resource.

## [0.11.0] - 2020-01-22 [YANKED]

### Updated

- Base container image has been updated to `openjdk:13.0.1-slim`
- The bundled sonar-scanner-cli has been updated to v4.2.0.1873.
- The bundled Maven command line has been updated to v3.6.3.
- The bundled sonar-maven-plugin has been updated to v3.7.0.1746.

### Fixed

- The TypeScript (`tsc`) command line has been removed in a prior version of the
  resource without proper notice. This breaks existing build pipelines that rely
  upon tsc's existence and therefore TypeScript has been re-added to the image
  and is now properly being version-managed. ([#48](https://github.com/cathive/concourse-sonarqube-resource/issues/48))

### Improved

- A container structure test has been added to the repository to make sure that
  the resource won't break as easily when updates are being made under the hood.
  ([#48](https://github.com/cathive/concourse-sonarqube-resource/issues/48), [#49](https://github.com/cathive/concourse-sonarqube-resource/issues/49))

## [0.10.0] - 2019-11-13

Thanks to [Fernando Torres](https://github.com/fftorres) for all the fixes and
enhancements that went into this release!

### Added

- Add support for Pull Request decorations.

### Fixed

- Fixed an issue when parsing the project status after analysis. ([#44](https://github.com/cathive/concourse-sonarqube-resource/issues/44))
- Fixed behavior of the defunct `autodetect_branch_name` flag.

## [0.9.1] - 2019-08-23

### Added

- Improved support for wildcard path arguments for properties
ending with `*reportPaths`.

### Updated
- Corrected some documentation.

## [0.9.0] - 2019-07-26

### Added

- New optional `out` step parameter: `project_key_file`.
  Thanks to [Guillaume Pouilloux](https://github.com/gpouilloux) for the patch.
- New optional `in` step parameter: `quality_gate`
  Thanks to [Ming Xu](https://github.com/SimonXming) for the patch.
- Support for Wildcard path arguments.
  Thanks to [Ming Xu](https://github.com/SimonXming) for the patch.
- The output now contains additional metadata about quality gate status conditions
  Thanks to [Ye Yang](https://github.com/mgsolid) for the patch.

### Updated

- The bundled sonar-scanner-cli has been updated to v4.0.0.1744.
- The bundled Maven command line has been updated to v3.6.1.

## [0.8.1] - 2019-01-29

### Fixed

- `params.maven_settings_file` should no longer be ignored.
  ([#36](https://github.com/cathive/concourse-sonarqube-resource/issues/36))

## [0.8.0] - 2019-01-25

### Added

- Error handling when fetching the compute engine status has been improved.
  Thanks to [Rekha Mittal](https://github.com/rekhamitt) for the provided
  patch. ([#33](https://github.com/cathive/concourse-sonarqube-resource/issues/33))
- A new flag (`additional_properties_file`) can be used to instrument the
  sonar-scanner. Thanks to [Horst Gutmanm](https://github.com/zerok) for the
  provided patch.

### Updated

- The bundled sonar-scanner-cli has been updated to v3.3.0.1492.
- The bundled sonar-maven-plugin has been updated to v3.6.0.1398.

### Fixed

- Fix issues when an auth-token (instead of username + password) is being used
  for authentication/authorization. Thanks to [Febin Rejoe](https://github.com/febinrejoe)
  for the provided fix. ([#31](https://github.com/cathive/concourse-sonarqube-resource/issues/31))

## [0.7.2] - 2018-12-09

### Added

- If the specified URL of the SonarQube server instance
  doesn't end in a slash, the missing slash will be appended
  automatically. ([#20](https://github.com/cathive/concourse-sonarqube-resource/issues/20))

## [0.7.1] - 2018-12-09

### Fixed

- scanner-report.txt could not be found if `scanner_type` was set to `maven` ([#24](https://github.com/cathive/concourse-sonarqube-resource/issues/24))
- Version 0.7.0 contained a bug where the bundled sonar-maven-plugin was *not* updated
  to version v3.5.0.1254 as originally announced. This version fixes this issue and
  makes sure that the desired version of he sonar-maven-plugin is being used.

## [0.7.0] - 2018-12-07

### Fixed

- Custom maven settings are used correctly when perfoming SonarQube analysis. Thanks to [Marek Urban](https://github.com/marek-urban) for the provided fix.
  ([#19](https://github.com/cathive/concourse-sonarqube-resource/issues/19))
- Docker builds should no longer fail because of corrupted sonar-scanner
  zip archive. ([#26](https://github.com/cathive/concourse-sonarqube-resource/issues/26))
- Anonymous access to SonarQube servers that don't require authentication
  should now be possible. ([#25](https://github.com/cathive/concourse-sonarqube-resource/issues/25))

### Added

- The integrity of the bundled Maven installation and the sonar-scanner
  distribution is now being checked agains sha512 checksums to ensure the contents of the downloads has not been altered.

### Updated

- The bundled Maven installation has been updated to v3.6.0.
- The bundled sonar-maven-plugin has been updated to v3.5.0.1254.

## [0.6.0] - 2018-05-30

### Removed

- The idea of using a project-local maven wrapper instance seemed nice but
  was not really usable / stable in practice. Therefore the feature had to
  be removed.

## [0.5.1] - 2018-05-30

### Fixed

- An issue with using the maven wrapper was introduced in 0.5.0.
  If a project uses the maven wrapper and the scanner_type is set to `maven`
  (or the scanner_type was automatically detected), such builds were broken,
  because the maven wrapper was not executed correctly.

## [0.5.0] - 2018-05-30

### Fixed

- Anonymous analysis without username/password or access token should now be possible.
  ([#13](https://github.com/cathive/concourse-sonarqube-resource/issues/13))

### Added

- A new configuration parameter (`source.__debug`) has been added that can be used
  to debug the resource itself when developing new features or fixing bugs.
  (This flag is *not* ment to be used in production environments, though!)

- The unit test framework has been enhanced and it should now be possible to write
  some real proper unit tests using the "bats" framework.

- If the scanner type has been set to `maven` (or if it has been automatically
  determined by the existence of a pom.xml file), the resource will now use the
  installed maven wrapper (if there is an executable `mvww` file in the project's
  root folder).

### Changed

- Starting with this release, the shell scripts will use BASH's double brackets
  syntax for all if-checks, because it's generally less error-prone and and offers
  fewer surprises when dealing with nasty things such as uninitialized variables.

## [0.4.0] - 2018-05-27

### Added

- `sonar.branch.name` can now be auto-detected if `params.autodetect_branch_name` has
  been set to `true`.
  ([#3](https://github.com/cathive/concourse-sonarqube-resource/issues/3))

### Changed

- Update sonar-scanner-cli to v3.2.0
- Update sonar-maven-plugin to v3.4.0

## [0.3.1] - 2018-05-16

### Fixed

- Multiple additional parameters work now as supposed to.
  ([#14](https://github.com/cathive/concourse-sonarqube-resource/issues/14))

## [0.3.0] - 2018-03-28

### Added

- Workaround for buggy certificate propagations in Alpine OpenJDK images.
  ([#16](https://github.com/cathive/concourse-sonarqube-resource/issues/16))

## [0.2.0] - 2018-02-07

### Fixed

- Parameters that contain whitespace characters no longer fail the `out` action.
  ([#6](https://github.com/cathive/concourse-sonarqube-resource/issues/6))

### Added

- Support for `params.tests`.
  ([#7](https://github.com/cathive/concourse-sonarqube-resource/issues/7))

- Support for `params.branch_name` and `params.branch_target`.
  Requires the [Branch Plugin](https://docs.sonarqube.org/display/PLUG/Branch+Plugin) or
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

- Support old SonarQube servers that don't report the server version in report-task.txt (Just report "unknown" as server version) ([#11](https://github.com/cathive/concourse-sonarqube-resource/issues/11))

## [0.0.31] - 2018-01-23

### Fixed

- Support old SonarQube servers that don't report the server version in report-task.txt (under certain conditions, this fix will not work though) ([#11](https://github.com/cathive/concourse-sonarqube-resource/issues/11))

## [0.0.30] - 2018-01-18

### Added

- Support for any additional properties that might need to be passed to the sonar-scanner.

### Fixed

- Updated the documentation to make clear how a quality gate can be used to break the build.
  ([#9](https://github.com/cathive/concourse-sonarqube-resource/issues/9))

## [0.0.20] - 2018-01-04

### Added

- Support for SonarQube/SonarCloud organizations. ([#8](https://github.com/cathive/concourse-sonarqube-resource/issues/8))
