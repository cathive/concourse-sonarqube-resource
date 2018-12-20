#!/bin/bash

function error() {
    JOB="${0}"              # job name
    LASTLINE="${1}"         # line of error occurrence
    LASTERR="${2}"          # error code
    echo "ERROR in ${JOB} : line ${LASTLINE} with exit code ${LASTERR}" >&2
    exit 1
}
trap 'error ${LINENO} ${?}' ERR

TMPDIR="${TMPDIR:-/tmp}"

function enable_debugging {
  if [[ "${1}" == "true" ]]; then
    echo "WARNING: Enabling debug output."
    echo "         You should *not* set this value in a production environment, because"
    echo "         it might leak sensitive information (such as passwords or access key"
    echo "         credentials to the console's output which might be accessible by un-"
    echo "         authorized / anonymous users."
    set -x
  fi
}

# Adds a trailing slash to the specified base URL if it has not
# already been added before and returns the sanitized URL.
# $1 URL to be sanitized
function sanitize_base_url {
  url="${1}"
  if [[ "${url:${#url}-1:1}" != "/" ]]; then
    url+="/"
  fi
  echo "${url}"
}

# Reads a properties file and returns a list of variable assignments
# that can be used to re-use these properties in a shell scripting environment.
function read_properties {
  if [[ "$2" == "shell" ]]; then
    awk -f "${root:?}/readproperties.awk" -v sv=1  < "${1}"
  else
    awk -f "${root:?}/readproperties.awk" -v sv=0  < "${1}"
  fi
}

# Checks on a compute engine task
# Params:
# $1 - Username or Access token, a colon and optional the password, e.g. "user:password" (required)
#      Pass an empty string to access SonarQube anonymously.
# $2 - SonarQube URL. Must end with a slash (required)
# $3 - CE Task ID (required)
function sq_ce_task {
  flags="-s -L"
  if [[ ! -z "${1}" ]] && [[ "${1}" != "" ]]; then
    flags+=" -u ${1}"
  fi
  url="${2}api/ce/task?id=${3}&additionalField=stacktrace,scannerContext"
  cmd="curl ${flags} ${url}"
  ${cmd}
}

# Checks the quality gate status of a project
# Params:
# $1 - Username or Access token, a colon and optional the password, e.g. "user:password" (required)
#      Pass an empty string to access SonarQube anonymously.
# $2 - SonarQube URL. Must end with a slash (required)
# $3 - Analysis ID (required)
function sq_qualitygates_project_status {
  flags="-s -L"
  if [[ ! -z "${1}" ]] && [[ "${1}" != "" ]]; then
    flags+=" -u ${1}"
  fi
  url="${2}api/qualitygates/project_status?analysisId=${3}"
  cmd="curl ${flags} ${url}"
  ${cmd}
}

# Retrieves the version of a SonarQube server instance
# If the version cannot be determined due to an error, the string
# "<unknown>" will be echoed.
# Params:
# $1 - Username or Access token, a colon and optional the password, e.g. "user:password" (required)
#      Pass an empty string to access SonarQube anonymously.
# $2 - SonarQube URL. Must end with a slash (required)
function sq_server_version {
  flags="-s -L"
  if [[ ! -z "${1}" ]] && [[ "${1}" != "" ]]; then
    flags+=" -u ${1}"
  fi
  url="${2}api/server/version"
  cmd="curl ${flags} ${url}"
  ${cmd}
}
