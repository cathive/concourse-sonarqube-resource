# [SonarQube](https://sonarqube.org/) Resource for [Concourse CI](https://concourse.ci/)

Performs SonarQube analyses and tracks the state of SonarQube [quality gates](https://docs.sonarqube.org/display/SONAR/Quality+Gates).

This resource works with [SonarCloud](https://sonarcloud.io/) and self-hosted instaces of SonarQube.

If you want to implement a real quality gate in your build pipeline, you might want to also use the [concourse-sonarqube-qualitygate-task](https://github.com/cathive/concourse-sonarqube-qualitygate-task) which can be used to break a build if certain quality goals (as reported by SonarQube) are not reached.

## Requirements

* A running SonarQube instance (this resource was tested on v6.5–v6.7, but it should
  work with every version of SonarQube ≥ v5.3)
* The base URL of your SonarQube server has to be configured correctly! Otherwise
  the resource will be unable to fetch analysis results when invoking it's `in`
  action. (`sonar.core.serverBaseURL` in `conf/sonar.properties`)

## Installation

Add a new resource type to your Concourse CI pipeline:

```yaml
 resource_types:
 - name: sonar-runner
  type: docker-image
  source:
    repository: cathive/concourse-sonarqube-resource
    tag: latest # For reproducible builds use a specific tag and don't rely on "latest".
```

## Source Configuration

* `host_url`: *Required.* The address of the SonarQube instance,
  e.g. "https://sonarcloud.io/" (when using SonarCloud). Must end with a slash.

* `organization`: The organization to be used when submitting stuff to a sonarqube
  instance. This field is *required* when using SonarCloud to perform the analysis
  of your code.

* `login`: *Required.* The login or authentication token of a SonarQube user with Execute Analysis
  permission.

* `password`: The password that goes with the sonar.login username. This should be left blank if an
  authentication token is being used.

* `maven_settings`: Maven settings to be used when performing SonarQube analysis.
  Only used if the scanner_type during the out phase has been set to / determined to use
  Maven.

## Behavior

The resource implements all three actions (check, in and out).
The analysis is triggered by the out action and check/in will be used to wait for
the result of the analysis and pull in the project status. Tasks can use this
information to break the build (if desired) if any of the criterias of the
quality gate associated with a project are not met.

### out: Trigger SonarQube analysis

#### Parameters

* `project_path`: *Required* Path to the resource that shall be analyzed.
  If the path contains a file called "sonar-project.properties" it will be picked
  up during analysis.
* `scanner_type`: Type of scanner to be used. Possible values are:
  * `auto` (default) Uses the maven-Scanner if a pom.xml is found in the directory
    specified by sources, cli otherwise.
  * `cli` Forces usage of the command line scanner, even if a Maven project object
    model (pom.xml) is found in the sources directory.
  * `maven` Forces usage of the Maven plugin to perform the scan.
* `project_key`: Project key (default value is read from sonar-project.properties)
* `project_name`: Project name (default value is read from sonar-project.properties)
* `project_description`: Project description (default value is read from sonar-project.properties)
* `project_version`: Project version (default value is read from sonar-project.properties)
* `project_version_file`: File to be used to read the Project version. When this option has been specified, it has precedence over the project_version parameter.
* `branch`: SCM branch. Two branches of the same project are considered to be different projects in SonarQube. Therefore, the default SonarQube behavior is to set the branch to an empty string.
* `analysis_mode`: One of
  * `publish` - this is the default. It tells SonarQube to perform a full, store-it-in-the-database analysis.
  * `preview` - Currently not supported by this resource!
  * `issues` - Currently not supported by this resource!
* `sources`: Comma-separated paths to directories containing source files.
* `additional_properties`: Optional object/dictionary that may contain any additional properties
  that one might want to pass when running the sonar-scanner.
* `maven_settings_file`: Path to a Maven settings file that shall be used.
  Only used if the scanner_type during has been set to / determined to use Maven.
  If the resource itself has a maven_settings configuration, this key will override
  it's value.

### in: Fetch result of SonarQube analysis

The action will place two JSON files into the resource's folder which are fetched from
the SonarQube Web API:

* qualitygate_project_status.json
  Quality gate status of the compute engine task that was triggered by the resource
  during the out action.
  Format: https://next.sonarqube.com/sonarqube/web_api/api/qualitygates/project_status
* ce_task_info.json
  Information about the compute engine task that performed the analysis.
  Format: https://next.sonarqube.com/sonarqube/web_api/api/ce/task

## Full example

The following example pipeline shows how to use the resource to break the build if
a project doesn't meet the requirements of the associated quality gate.

```yaml
resource_types:

- name: sonar-runner
  type: docker-image
  source:
    repository: cathive/concourse-sonarqube-resource
    tag: latest # For reproducible builds use a specific tag and don't rely on "latest".

resources:

- name: example-sources-to-be-analyzed
  type: git
  source:
    uri: https://github.com/example/example.git
- name: code-analysis
  type: sonar-runner
  source:
    host_url: https://sonarqube.example.com/
    login: ((sonarqube-auth-token))
    project_key: com.example.my_project

jobs:

- name: build-and-analyze
  plan:
  - get: example-sources-to-be-analyzed
    trigger: true
  - task: build
    config:
      platform: linux
      image_resource:
        type: docker-image
        source:
          repository: debian
          tag: 'jessie'
        inputs:
        - name: example-sources
        outputs:
        # Hint: For some (most?) languages, the sonar-runner needs more than just the
        # sources to perform a full analysis. Line coverage reports, unit test reports,
        # Java class files and mutation test results should also be present.
        # Therefore, you'll have to make sure that your build script provides the sources
        # and the compilation/test in your Concourse CI build plan.
        # (And that is the reason, why we need the following output)
        - name: sonarqube-analysis-input
         run:
           path: build.sh
           dir: example-sources
  - put: code-analysis
    params:
      project_path: sonarqube-analysis-input
      additional_properties:
        # Will be passed as "-Dsonar.javascript.lcov.reportPaths="coverage/lcov.info" to the scanner.
        sonar.javascript.lcov.reportPaths: coverage/lcov.info
- name: qualitygate
  plan:
  - get: code-analysis
    passed:
    - build-and-analyze
    trigger: true
  - task: check-sonarqube-quality-gate
    config:
      platform: linux
      image_resource:
        type: docker-image
        source:
          repository: cathive/concourse-sonarqube-qualitygate-task
          tag: latest # Use one of the versioned tags for reproducible builds!
      inputs:
      - name: code-analysis
      run:
        path: /sonarqube-qualitygate-check
        dir: code-analysis
```
