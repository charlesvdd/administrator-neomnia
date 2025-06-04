#!/usr/bin/env bash
#
# install.sh – GitHub validation (username + token) + repository clone
#
# Usage :
#   sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/charlesvdd/administrator-neomnia/api-key-github/install.sh)"
#

set -euo pipefail

# ————————————————————————————————————————————————
#  Define colors and display functions
# ————————————————————————————————————————————————
# Colors (ANSI codes)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Display functions
error() {
  echo -e "${RED}❌  $*${RESET}"
}

warning() {
  echo -e "${YELLOW}⚠️  $*${RESET}"
}

info() {
  echo -e "${CYAN}ℹ️  $*${RESET}"
}

success() {
  echo -e "${GREEN}✔️  $*${RESET}"
}

stage() {
  # Print a well-formatted step header
  local num="$1"; shift
  local msg="$*"
  echo -e "\n${MAGENTA}═════════════════════════════════════════════════${RESET}"
  echo -e "${MAGENTA}  [STEP $num] – $msg${RESET}"
  echo -e "${MAGENTA}═════════════════════════════════════════════════${RESET}\n"
}

# ————————————————————————————————————————————————
#  Display banner and license
# ————————————————————————————————————————————————
echo -e "${MAGENTA}┌─────────────────────────────────────────────────────────┐${RESET}"
echo -e "${MAGENTA}│                                                         │${RESET}"
echo -e "${MAGENTA}│    Neomnia Administrator Installer                      │${RESET}"
echo -e "${MAGENTA}│    by Charles Van Den Driessche                          │${RESET}"
echo -e "${MAGENTA}│      www.neomnia.net                                     │${RESET}"
echo -e "${MAGENTA}│                                                         │${RESET}"
echo -e "${MAGENTA}└─────────────────────────────────────────────────────────┘${RESET}"
echo -e "${GREEN}License: Charles Van Den Driessche – www.neomnia.net${RESET}"
echo

# ————————————————————————————————————————————————
# 1. Check for root privileges
# ————————————————————————————————————————————————
if [[ "$EUID" -ne 0 ]]; then
  error "This script must be run as root."
  info  "Please rerun with: sudo $0"
  exit 1
fi

# ————————————————————————————————————————————————
# 2. Prompt and validate GitHub username/token
# ————————————————————————————————————————————————
prompt_and_validate_github() {
  local http_code api_login
  while true; do
    stage 0 "GitHub Information"

    # Prompt for credentials
    read -p "$(echo -e ${BLUE}\"GitHub Username\":${RESET} ) " GITHUB_USER
    read -s -p "$(echo -e ${BLUE}\"GitHub API Key (input hidden)\":${RESET} ) " GITHUB_API_KEY
    echo -e "\n"

    # 2.1. Check token validity via /user
    http_code=$(curl -s -o /dev/null -w "%{http_code}" \
      -H "Authorization: token ${GITHUB_API_KEY}" \
      https://api.github.com/user)

    if [[ "$http_code" -ne 200 ]]; then
      warning "Authentication failed (HTTP ${http_code})."
      info    "Please check your API key and try again."
      echo
      continue
    fi

    # 2.2. Retrieve actual login from the JSON response
    api_login=$(curl -s \
      -H "Authorization: token ${GITHUB_API_KEY}" \
      https://api.github.com/user \
      | grep -m1 '"login"' | cut -d '"' -f4)

    if [[ "$api_login" != "$GITHUB_USER" ]]; then
      warning "The token provided does not belong to user '${GITHUB_USER}',"
      info    "but to '${api_login}'. Please re-enter your credentials."
      echo
      continue
    fi

    # Credentials are valid and match
    success "Authentication successful for user '${GITHUB_USER}'."
    export GITHUB_USER GITHUB_API_KEY
    break
  done
}

prompt_and_validate_github

# ————————————————————————————————————————————————
# 3. Clone or update the repository
# ————————————————————————————————————————————————
stage 1 "Cloning/updating the GitHub repository into /opt/administrator-neomnia"

REPO="administrator-neomnia"
TARGET_DIR="/opt/${REPO}"

if [[ -d "$TARGET_DIR" ]]; then
  info "The directory ${TARGET_DIR} already exists."
  info "→ Running git pull to update…"
  git -C "$TARGET_DIR" pull \
    && success "Repository update completed successfully."
else
  info "Cloning repository: ${GITHUB_USER}/${REPO}"
  git clone "https://${GITHUB_USER}:${GITHUB_API_KEY}@github.com/${GITHUB_USER}/${REPO}.git" \
    "$TARGET_DIR" \
    && success "Clone finished in '${TARGET_DIR}'."
fi

# ————————————————————————————————————————————————
# 4. End of script
# ————————————————————————————————————————————————
stage 2 "Finished"
success "Your repository is now cloned into '${TARGET_DIR}'."
echo
