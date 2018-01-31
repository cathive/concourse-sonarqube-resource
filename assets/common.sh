function error() {
    JOB="${0}"              # job name
    LASTLINE="${1}"         # line of error occurrence
    LASTERR="${2}"          # error code
    echo "ERROR in ${JOB} : line ${LASTLINE} with exit code ${LASTERR}" >&2
    exit 1
}
trap 'error ${LINENO} ${?}' ERR

TMPDIR="${TMPDIR:-/tmp}"

# Reads a properties file and returns a list of variable assignments
# that can be used to re-use these properties in a shell scripting environment.
function read_properties {
  awk -f "${root:?}/readproperties.awk" < "${1}"
}

# Checks on a compute engine task
# Params:
# $1 - Username or Access token, a colon and optional the password, e.g. "user:password" (required)
# $2 - SonarQube URL. Must end with a slash (required)
# $3 - CE Task ID (required)
function sq_ce_task {
  curl -s -L -u "${1}" "${2}api/ce/task?id=${3}&additionalField=stacktrace,scannerContext"
}

# Checks the quality gate status of a project
# Params:
# $1 - Username or Access token, a colon and optional the password, e.g. "user:password" (required)
# $2 - SonarQube URL. Must end with a slash (required)
# $3 - Analysis ID (required)
function sq_qualitygates_project_status {
  curl -s -L -u "${1}" "${2}api/qualitygates/project_status?analysisId=${3}"
}

# Retrieves the version of a SonarQube server instance
# If the version cannot be determined due to an error, the string
# "<unknown>" will be returned.
# Params:
# $1 - Username or Access token, a colon and optional the password, e.g. "user:password" (required)
# $2 - SonarQube URL. Must end with a slash (required)
function sq_server_version {
  curl -s -L -u "${1}" "${2}api/server/version" || echo "<unknown>"
}