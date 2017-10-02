# Reads a properties file and returns a list of variable assignments
# that can be used to re-use these properties in a shell scripting environment.
function read_properties {
  cat $1 | awk -f "${root}/readproperties.awk"
}