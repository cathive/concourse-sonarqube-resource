#!/usr/bin/env bats

setup() {
  export PATH="${BATS_TEST_DIRNAME}/mocks:${PATH}"
}

@test "Valid project" {

  # Variables
  WORKSPACE=$(mktemp -d "${BATS_TMPDIR}/test-project.XXXXXX")
  PROJECT_ROOT="${WORKSPACE}/cli_project"
  OUT_RESULT_FILE="${PROJECT_ROOT}/out_result.json"

  # Mock configuration
  export SONAR_SCANNER_REPORT_FILE_MOCK="${PROJECT_ROOT}/report-task.mock.txt"
  export SONAR_SCANNER_REPORT_FILE="${PROJECT_ROOT}/.scannerwork/report-task.txt"

  # Workspace preparation
  cp -a "${BATS_TEST_DIRNAME}/workspace/cli_project" "${WORKSPACE}/"
  mkdir -p "${PROJECT_ROOT}/.scannerwork"

  # Perform mock SonarQube analysis
  cat ./test/out_cli_project.json | ./assets/out "${WORKSPACE}" > "${OUT_RESULT_FILE}" # 2> /dev/null

}
