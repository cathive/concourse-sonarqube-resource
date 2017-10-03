# Reads a properties file and returns a list of variable assignments
# that can be used to re-use these properties in a shell scripting environment.
function read_properties {
  cat $1 | awk -f "${root}/readproperties.awk"
}

# Checks on a compute engine task
# Params:
# $1 - Username or Access token, a colon ans optional the password, e.g. "user:password" (required)
# $2 - SonarQube URL. Must end with a slash (required)
# $3 - CE Task ID (required)
function sq_ce_task {
  curl -s -L -u "${1}" "${2}api/ce/task?id=${3}&additionalField=stacktrace,scannerContext"
}

# Checks the quality gate status of a project
# Params:
# $1 - Username or Access token, a colon ans optional the password, e.g. "user:password" (required)
# $2 - SonarQube URL. Must end with a slash (required)
# $3 - Analysis ID (required)
function sq_qualitygates_project_status {
  curl -s -L -u ${1} "${2}api/qualitygates/project_status?analysisId=${3}"
}