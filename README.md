# SonarQube Resource

Performs SonarQube analyses and tracks the state of SonarQube quality gates.

## Installation
Add a new resource type to your Concourse CI pipeline:
```yaml
 resource_types:
 - name: sonarqube
  type: docker-image
  source:
    repository: cathive/concourse-sonarqube-resource
    tag: latest # For reproducible builds use a specific tag and don't rely on "latest".
```

## Source Configuration

* `host_url`: *Required.* The address of the SonarQube instance,
  e.g. "https://sonarqube.example.com/". Must end with a slash.

* `login`: *Required.* The login or authentication token of a SonarQube user with Execute Analysis
  permission.

* `password`: The password that goes with the sonar.login username. This should be left blank if an
  authentication token is being used.

* `maven_settings`: Maven settings to be used when performing SonarQube analysis.
  Only used if the scanner_type during the out phase has been set to / determined to use
  Maven.

 ### Example
 
 ```yaml
resources:
- name: example-src
  type: git
  source:
    uri: https://github.com/example/example.git
- name: example-analysis
  type: sonarqube
  source:
    host_url: https://sonarqube.example.com/
    login: ((SONARQUBE_AUTH_TOKEN))
    project_key: com.example.my_project
    branch: master
 ```

## Behavior

### out: Perform SonarQube analysis

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
* `sources`: Comma-separated paths to directories containing source files.
* `maven_settings_file`: Path to a Maven settings file that shall be used.
  Only used if the scanner_type during has been set to / determined to use Maven.
  If the resource itself has a maven_settings configuration, this key will override
  it's value.