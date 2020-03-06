# [SonarQube](https://sonarqube.org/) Resource for [Concourse CI](https://concourse.ci/)

Performs SonarQube analyses and tracks the state of SonarQube [quality gates](https://docs.sonarqube.org/display/SONAR/Quality+Gates).

This resource works with [SonarCloud](https://sonarcloud.io/) and self-hosted instaces of SonarQube.

If you want to implement a real quality gate in your build pipeline, you might want to also use the [concourse-sonarqube-qualitygate-task](https://github.com/cathive/concourse-sonarqube-qualitygate-task) which can be used to break a build if certain quality goals (as reported by SonarQube) are not reached.

## Requirements

* A running SonarQube instance (this resource was tested on v6.5–v7.1, but it should
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

* `login`: The login or authentication token of a SonarQube user with Execute Analysis
  permission. Can be left out if SonarQube instance does not require any authentication.

* `password`: The password that goes with the sonar.login username. This should be left blank if an
  authentication token is being used.

* `maven_settings`: Maven settings to be used when performing SonarQube analysis.
  Only used if the scanner_type during the out phase has been set to / determined to use
  Maven.

* `__debug`: This flag is used to debug any problems that might occur when using the resource
  itself. It enables extra debug output on the console and sets the `-x` flag during shell
  execution. It is usually not a good idea to set this flag to `true` in a production environment,
  because it might leak passwords and access key credentials to the console where it might
  be accessed by unauthorized / anonymous users.

## Behavior

The resource implements all three actions (check, in and out).
The analysis is triggered by the out action and check/in will be used to wait for
the result of the analysis and pull in the project status. Tasks can use this
information to break the build (if desired) if any of the criteria of the
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

* `project_key_file`: File to be used to read the Project key.
  When this option has been specified, it has precedence over the `project_key` parameter.

* `project_name`: Project name (default value is read from sonar-project.properties)

* `project_description`: Project description (default value is read from sonar-project.properties)

* `project_version`: Project version (default value is read from sonar-project.properties)

* `project_version_file`: File to be used to read the Project version.
  When this option has been specified, it has precedence over the `project_version` parameter.

* `autodetect_branch_name`: Try to figure out the branch automatically.
  This works if the `project_path` contains recognized SCM metadata from a supported
  revision control system. (Currently: only Git is supported!)

* `branch_name`: Name of the branch. Overrides `autodetect_branch_name` if it has been set.

* `branch_name_file`: File to be used to read the branch name.
  When this option has been specified, it has precedence over the `branch_name` parameter.

* `branch_target`: Name of the branch where you intend to merge your short-lived branch at the end of its life.
  If left blank, this defaults to the master branch. It can also be used while initializing a long-lived
  branch to sync the issues from a branch other than the Main Branch.
  (See [Branch Plugin documentation](https://docs.sonarqube.org/display/PLUG/Branch+Plugin) for further
  details)

* `branch_target_file`: File to be used to read the branch target.
  When this option has been specified, it has precedence over the `branch_target` parameter.

* `decorate_pr`: If set to `true` it will try to fetch the pull request id and the head branch name from
the pull request resource. It works for `telia-oss/github-pr-resource` and `jtarchie/github-pullrequest-resource`. It will enable `sonar.pullrequest.key` and `sonar.pullrequest.branch` flags when performing your analysis.

  >_In order to use this feature you must be using `SonarCloud` or `SonarQube Developer` edition._

* `sources`: A list of paths to directories containing source files.

* `tests`: A list of paths to directories containing source files.

* `additional_properties`: Optional object/dictionary that may contain any additional properties
  that one might want to pass when running the sonar-scanner.

* `additional_properties_file`: Optional path to a file containing properties
  that should be passed to the sonar-scanner.

* `maven_settings_file`: Path to a Maven settings file that shall be used.
  Only used if the scanner_type during has been set to / determined to use Maven.
  If the resource itself has a maven_settings configuration, this key will override
  it's value.

* `sonar_maven_plugin_version`: sonar-maven-plugin version (default is empty and using the latest version)

#### Wildcards Support

Support convert wildcards to comma-separated paths.

* `sources`
* `tests`
* Any key with the suffix `.reportPaths` in `additional_properties`

### in: Fetch result of SonarQube analysis

The action will place two JSON files into the resource's folder which are fetched from
the SonarQube Web API:

#### Parameters

* `quality_gate`: *Optional* *JSON* Enable quality_gate checker and control `get` step success/failure.
  * `ignore_all_warn`: *bool* Ignore all `WARN` metrics and let `get` step success
  * `ignore_all_error`: *bool* Ignore all `ERROR` metrics and let `get` step success
  * `ignore_warns`: *array* A list of metric keys for `WARN` metric to ignore while quality_gate checking.
  * `ignore_errors`: *array* A list of metric keys for `ERROR` metric to ignore while quality_gate checking.

Note: for `ignore_warns`/`ignore_errors`, possible value could be found through
* `https://<your-sonar_host>/quality_gates/show/<quality_gate_id>`
* `https://<your-sonar_host>/api/qualitygates/show?id=<quality_gate_id>`

### Outputs

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

- name: sources
  type: git
  source:
    uri: https://github.com/example/example.git

- name: artifact
  type: s3
  # ... configuration ommited

- name: code-analysis
  type: sonar-runner
  source:
    host_url: https://sonarqube.example.com/
    login: ((sonarqube-auth-token))

jobs:

# The build job performs fetches stuff from the "sources" resource
# and executes a task that builds and tests everyhing. Once compilation,
# test execution and <whatever> has been performed, we copy the whole
# working directory into the output folder "sonarqube-analysis-input"
# and push the package that has been created by the "build" task to the
# artifact resource and utilize the sonarqube-resource to perform static
# code analysis.
- name: build-and-analyze
  plan:
  - get: sources
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
      - name: sources
      outputs:
      # Hint: The sonar-runner needs more than just the
      # sources to perform a full analysis. Line coverage reports, unit test reports,
      # Java class files and mutation test results should also be present.
      # Therefore, you'll have to make sure that your build script provides the sources
      # and the compilation/test results in your Concourse CI build plan.
      # (And that is the reason, why we need the following output)
      - name: sonarqube-analysis-input
      run:
        path: build.sh
        dir: sources
  - in_parallel:
    - put: code-analysis
      params:
        project_path: sonarqube-analysis-input
        project_key: com.example.my_project
        sources: ["."]
        tests: ["."]
        additional_properties:
          # Will be passed as "-Dsonar.javascript.lcov.reportPaths="coverage/lcov.info" to the scanner.
          sonar.javascript.lcov.reportPaths: coverage/lcov.info
      get_params:
        quality_gate:
          ignore_errors: ['new_coverage', 'violations']
          ignore_warns: ['new_duplicated_lines_density', 'violations']
    - put: artifact

# The qualitygate task breaks the build if the analysis result from SonarQube
# indicates that any of our quality metrics have not been met.
- name: qualitygate
  plan:
  - in_parallel:
    - get: artifact
      passed:
      - build-and-analyze
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

# We deploy only artifacts that have made it through our quality gate!
- name: deploy
  plan:
  - get: artifact
    passed:
    - qualitygate

```
