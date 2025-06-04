#!/usr/bin/env bash
#
# install.sh – Repository clone while storing login+token in /root/.netrc
#
# Usage:
#   sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/charlesvdd/administrator-neomnia/api-key-github/install.sh)"
#
# This script:
#   1. Checks if /root/.netrc exists and is functional.
#   2. If it doesn’t exist, prompts for login+token, creates it, and secures it (chmod 600).
#   3. Validates the login/token pair by calling the GitHub API.
#   4. Clones (or updates) the repository into /opt/administrator-neomnia.
#

set -euo pipefail

# 1. Verify that the script is running as root
if [[ "$EUID" -ne 0 ]]; then
  echo "❌ This script must be run as root."
  echo "   Please run it with: sudo $0"
  exit 1
fi

NETRC_PATH="/root/.netrc"

# 2. If /root/.netrc doesn’t exist, ask for login+token and write it
if [[ ! -r "$NETRC_PATH" ]]; then
  echo "===== [Step 0] — Configuring /root/.netrc ====="
  read -p "GitHub username: " GITHUB_USER
  read -s -p "GitHub API key (token): " GITHUB_API_KEY
  echo -e "\n"

  # Create /root/.netrc
  cat > "$NETRC_PATH" <<EOF
machine github.com
  login $GITHUB_USER
  password $GITHUB_API_KEY
EOF
  chmod 600 "$NETRC_PATH"
  echo "✔ /root/.netrc has been created and secured (chmod 600)."
else
  # If it already exists, read the login to display it
  GITHUB_USER=$(grep -m1 '^  login ' "$NETRC_PATH" | cut -d ' ' -f3)
  echo "ℹ️ /root/.netrc found (login: $GITHUB_USER)."
fi

# 3. Verify that the token stored in /root/.netrc is valid
echo "===== [Step 1] — Validating the GitHub token ====="
http_code=$(curl -s -n -o /dev/null -w "%{http_code}" https://api.github.com/user)
if [[ "$http_code" -ne 200 ]]; then
  echo "❌ The login or token in /root/.netrc appears invalid (HTTP $http_code)."
  echo "   Please remove /root/.netrc and rerun the script to re-enter credentials."
  exit 1
fi

# Optionally: retrieve the actual login for confirmation
current_login=$(curl -s -n https://api.github.com/user | grep -m1 '"login"' | cut -d '"' -f4)
if [[ "$current_login" != "$GITHUB_USER" ]]; then
  echo "❌ The token belongs to '$current_login', but /root/.netrc indicates login='$GITHUB_USER'."
  echo "   Please remove /root/.netrc and rerun the script to correct it."
  exit 1
fi
echo "✔ GitHub authentication succeeded for: $current_login"

# 4. Utility function to print step headers
stage() {
  local num="$1"; shift
  local msg="$*"
  echo -e "\n===== [Step $num] — $msg ====="
}

# 5. Clone or update the repository in /opt/administrator-neomnia
stage 2 "Cloning/updating the GitHub repository into /opt/administrator-neomnia"
REPO="administrator-neomnia"
TARGET_DIR="/opt/${REPO}"

if [[ -d "$TARGET_DIR" ]]; then
  echo "→ The directory ${TARGET_DIR} already exists. Performing git pull…"
  git -C "$TARGET_DIR" pull
else
  echo "→ Cloning the repo https://github.com/${current_login}/${REPO}.git"
  git clone "https://github.com/${current_login}/${REPO}.git" "$TARGET_DIR"
fi

# 6. End of script
stage 3 "Finished"
echo "✅ Your repository has been cloned/updated into: ${TARGET_DIR}"
echo "   Next time, /root/.netrc will be read automatically, and you won’t need to re-enter credentials."
