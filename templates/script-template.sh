#!/bin/bash
# script-name.sh - Brief description of what this script does
#
# Usage:
#   ./script-name.sh [OPTIONS] [ARGS]
#
# Options:
#   -h, --help      Show this help message
#   -d, --debug     Enable debug mode
#   -v, --verbose   Verbose output
#
# Examples:
#   ./script-name.sh
#   ./script-name.sh --debug

set -eo pipefail

# ==================== COLORS ====================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

# ==================== CONFIGURATION ====================
DEBUG=0
VERBOSE=0

# ==================== FUNCTIONS ====================

show_help() {
  cat << EOF
${BOLD}${CYAN}script-name.sh${NC} - Brief description

${BOLD}USAGE:${NC}
  ./script-name.sh [OPTIONS] [ARGS]

${BOLD}OPTIONS:${NC}
  ${GREEN}-h, --help${NC}      Show this help message
  ${GREEN}-d, --debug${NC}     Enable debug mode (dry-run)
  ${GREEN}-v, --verbose${NC}   Verbose output

${BOLD}EXAMPLES:${NC}
  ${DIM}# Basic usage${NC}
  ./script-name.sh
  
  ${DIM}# Debug mode${NC}
  ./script-name.sh --debug

${BOLD}DESCRIPTION:${NC}
  Add a longer description here explaining what your script does,
  its purpose, and any important details users should know.

EOF
  exit 0
}

log() {
  echo -e "${BLUE}ℹ${NC} $*"
}

success() {
  echo -e "${GREEN}✓${NC} $*"
}

error() {
  echo -e "${RED}✗${NC} $*" >&2
}

warning() {
  echo -e "${YELLOW}⚠${NC} $*"
}

debug() {
  if [[ $DEBUG -eq 1 ]]; then
    echo -e "${DIM}[DEBUG]${NC} $*"
  fi
}

# ==================== ARG PARSING ====================

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_help
      ;;
    -d|--debug)
      DEBUG=1
      shift
      ;;
    -v|--verbose)
      VERBOSE=1
      shift
      ;;
    *)
      error "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# ==================== MAIN LOGIC ====================

main() {
  log "Starting script..."
  
  # Your code here
  
  if [[ $DEBUG -eq 1 ]]; then
    debug "Debug mode enabled"
    warning "This is a dry-run, no changes will be made"
    # Show what would happen
  else
    # Do actual work
    success "Task completed successfully"
  fi
}

# ==================== EXECUTION ====================

main "$@"
