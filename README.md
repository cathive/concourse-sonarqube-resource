# SonarQube Resource

Performs SonarQube analyses and tracks the state of SonarQube quality gates.

## Source Configuration

* `host_url`: *Required.* The address of the SonarQube instance.

* `login`: *Required.* The login or authentication token of a SonarQube user with Execute Analysis
  permission.

* `password`: The password that goes with the sonar.login username. This should be left blank if an
  authentication token is being used.

 ### Example
 ```yaml
 resource_types:
 - name: sonarqube
  type: docker-image
  source:
    repository: cathive/concourse-sonarqube-resource
    tag: latest
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
* `project_path`: *Required* Path to the resource that shall be analyzed.
  If the path contains a file called "sonar-project.properties" it will be picked
  up during analysis.
* `project_key`: Project key (default value is read from sonar-project.properties)
* `sources`: Comma-separated paths to directories containing source files.