#!/usr/bin/env bash

set -euo pipefail

# Function to encode credentials
encode_github_credentials() {
  local username="$1"
  local api_key="$2"
  echo "$username:$api_key" | base64
}

# Function to decode credentials
decode_github_credentials() {
  local encoded_credentials="$1"
  echo "$encoded_credentials" | base64 --decode
}

# Prompt and validate GitHub credentials
prompt_and_validate_github() {
  local http_code api_login
  while true; do
    echo "===== [Step 0] — GitHub Information ====="
    read -p "GitHub Username: " GITHUB_USER
    read -s -p "GitHub API Key (hidden input): " GITHUB_API_KEY
    echo -e "\n"

    http_code=$(curl -s -o /dev/null -w "%{http_code}" \
      -H "Authorization: token ${GITHUB_API_KEY}" \
      https://api.github.com/user)

    if [[ "$http_code" -ne 200 ]]; then
      echo "⚠️ Authentication failed (HTTP ${http_code})."
      echo "   Please check your API key and try again."
      echo
      continue
    fi

    api_login=$(curl -s \
      -H "Authorization: token ${GITHUB_API_KEY}" \
      https://api.github.com/user \
      | grep -m1 '"login"' | cut -d '"' -f4)

    if [[ "$api_login" != "$GITHUB_USER" ]]; then
      echo "⚠️ The provided token does not belong to the user '$GITHUB_USER',"
      echo "   but to '$api_login'. Please re-enter the information."
      echo
      continue
    fi

    echo "✔ Authentication successful for user '${GITHUB_USER}'."
    export GITHUB_USER GITHUB_API_KEY

    # Encode and store the credentials
    encoded_credentials=$(encode_github_credentials "$GITHUB_USER" "$GITHUB_API_KEY")
    echo "$encoded_credentials" > /path/to/encoded_credentials.txt
    break
  done
}

# Example of decoding and using the information
# encoded_credentials=$(cat /path/to/encoded_credentials.txt)
# decoded_credentials=$(decode_github_credentials "$encoded_credentials")
# GITHUB_USER=$(echo "$decoded_credentials" | cut -d: -f1)
# GITHUB_API_KEY=$(echo "$decoded_credentials" | cut -d: -f2)

prompt_and_validate_github

stage() {
  local num="$1"; shift
  local msg="$*"
  echo -e "\n===== [Step $num] — $msg ====="
}

stage 1 "Cloning/updating the GitHub repository to /opt/administrator-neomnia"

REPO="administrator-neomnia"
TARGET_DIR="/opt/${REPO}"

if [[ -d "$TARGET_DIR" ]]; then
  echo "→ The directory ${TARGET_DIR} already exists. Performing a git pull to update."
  git -C "$TARGET_DIR" pull
else
  echo "→ Cloning from GitHub: ${GITHUB_USER}/${REPO}"
  git clone "https://${GITHUB_USER}:${GITHUB_API_KEY}@github.com/${GITHUB_USER}/${REPO}.git" "$TARGET_DIR"
fi

stage 2 "Finished"
echo "✅ Your repository is now cloned into '${TARGET_DIR}'."
