#!/bin/bash
#____________________________________________________________________________________
# Make sure to include the following code at the end of any script that uses debug.sh
# # Disable tracing before exit (if enabled)
# if [[ "$DEBUG" -eq 1 ]]; then
#   set +x
# fi
#____________________________________________________________________________________

# Set DEBUGNAME to the base filename of the sourcing script (without .sh extension)
DEBUGNAME=$(basename "$0" .sh)

# Define log file names
DEBUG_A="./.debug/debug_${DEBUGNAME}_A.log"
DEBUG_B="./.debug/debug_${DEBUGNAME}_B.log"

# Enable strict modes for better error handling
set -euo pipefail

# Toggle debug mode with an environment variable (e.g., DEBUG=1)
DEBUG=${DEBUG:-0}

# Copy existing DEBUG_A to DEBUG_B if it exists
if [[ -f "$DEBUG_A" ]]; then
  cp -f "$DEBUG_A" "$DEBUG_B" || {
    echo "Error: Failed to copy $DEBUG_A to $DEBUG_B" >&2
    exit 1
  }
fi

# Redirect all output (stdout and stderr) to tee DEBUG_A
exec > >(tee "$DEBUG_A") 2>&1

# Logging functions
log() {
  local level="$1"
  local message="$2"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$timestamp] [$level] $DEBUGNAME: $message"
}

debug() {
  if [[ "$DEBUG" -eq 1 ]]; then
    local message="$1"
    local line=$(caller 0 | awk '{print $1}')
    local func=$(caller 0 | awk '{print $2}')
    log "DEBUG" "Line $line ($func): $message"
  fi
}

error() {
  local message="$1"
  log "ERROR" "$message"
  exit 1
}

# Trap errors and log them
trap 'error "Script failed at line $LINENO with status $?"' ERR

# Enable command tracing if DEBUG is enabled
if [[ "$DEBUG" -eq 1 ]]; then
  set -x
fi