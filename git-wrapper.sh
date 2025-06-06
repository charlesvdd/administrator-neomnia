#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# MIT License
#
# Copyright (c) 2025 Charles VDD
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the “Software”), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
# -----------------------------------------------------------------------------

# =============================================================================
#    ____ _ _   _   _       _    _ _     _   _ _ _
#   / ___(_) |_| | | |_   _| | _(_) | __| | | (_) |_ ___
#  | |  _| | __| |_| | | | | |/ / | |/ _` | | | | __/ _ \
#  | |_| | | |_|  _  | |_| |   <| | | (_| | | | | ||  __/
#   \____|_|\__|_| |_|\__,_|_|\_\_|_|\__,_|_|_|_|\__\___|
#
#           Git & GitHub CLI Automatic Installer
# =============================================================================
# A clean, interactive script to install Git and GitHub CLI, then authenticate
# with your GitHub account using a Personal Access Token (PAT). Displays a
# friendly banner and re-prompts on any authentication error.
# -----------------------------------------------------------------------------

set -euo pipefail

# URL for relaunching the script when piping
readonly SCRIPT_URL="https://raw.githubusercontent.com/charlesvdd/administrator-neomnia/api-key-github/git-wrapper.sh"

# 0) Elevate to root if not already, to install packages
if [ "$EUID" -ne 0 ]; then
  echo -e "\n🔄 Relaunching script as root...\n"
  base0=$(basename "$0")
  if [ -f "$0" ] && [[ "$base0" != "bash" && "$base0" != "sh" ]]; then
    exec sudo bash "$0" "$@"
  else
    exec sudo bash -c "curl -sL $SCRIPT_URL | bash"
  fi
fi

# Now running as root
ORIGINAL_USER="${SUDO_USER:-$(id -un)}"
USER_HOME=$(eval echo "~$ORIGINAL_USER")

# -----------------------------------------------------------------------------
# 1) Install Git if missing
# -----------------------------------------------------------------------------
if ! command -v git &> /dev/null; then
  echo "🔄 Git not found. Installing Git..."
  if command -v apt-get &> /dev/null; then
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y git
  elif command -v yum &> /dev/null; then
    yum install -y git
  else
    echo "❌ No supported package manager (apt-get or yum) found. Please install Git manually."
    exit 1
  fi

  if ! command -v git &> /dev/null; then
    echo "❌ Failed to install Git. Please install Git manually."
    exit 1
  fi
  echo "✅ Git installed successfully."
else
  echo "✅ Git is already installed."
fi

# -----------------------------------------------------------------------------
# 2) Install GitHub CLI (gh) if missing
# -----------------------------------------------------------------------------
if ! command -v gh &> /dev/null; then
  echo "🔄 GitHub CLI (gh) not found. Installing gh..."
  if command -v apt-get &> /dev/null; then
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y gh
  elif command -v yum &> /dev/null; then
    yum install -y https://github.com/cli/cli/releases/download/v2.46.0/gh_2.46.0_linux_amd64.rpm
  else
    echo "❌ No supported package manager (apt-get or yum) found. Please install GitHub CLI manually."
    exit 1
  fi

  if ! command -v gh &> /dev/null; then
    echo "❌ Failed to install GitHub CLI. Please install gh manually."
    exit 1
  fi
  echo "✅ GitHub CLI installed successfully."
else
  echo "✅ GitHub CLI is already installed."
fi

# -----------------------------------------------------------------------------
# 3) Interactive loop: prompt for GitHub username and PAT until authentication succeeds
# -----------------------------------------------------------------------------
while true; do
  echo -e "\n🔐 Please enter your GitHub credentials."
  # Prompt for GitHub username
  read -p "   • GitHub Username: " GITHUB_USER
  # Determine PAT: from env or prompt
  if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    PAT="$GITHUB_TOKEN"
    echo "   • PAT loaded from GITHUB_TOKEN environment variable."
  else
    if [[ ! -t 0 ]]; then
      echo "❌ No TTY available to enter PAT. Please set GITHUB_TOKEN or run in a terminal."
      exit 1
    fi
    read -s -p "   • Personal Access Token (input hidden): " PAT
    echo
  fi

  # Attempt to authenticate gh under the original user
  DECODED_TOKEN="$PAT"
  echo "   • Attempting to authenticate with GitHub CLI..."
  if sudo -u "$ORIGINAL_USER" bash -c "printf '%s' \"$DECODED_TOKEN\" | gh auth login --with-token" &> /dev/null; then
    echo "✅ Authentication succeeded."
    break
  else
    echo "❌ Authentication failed. Please check your username and token and try again."
  fi
done

# -----------------------------------------------------------------------------
# 4) Encode PAT in Base64 and store in ~/.github_token
# -----------------------------------------------------------------------------
ENCODED_TOKEN=$(printf "%s" "$PAT" | base64)
TOKEN_FILE="$USER_HOME/.github_token"
printf "%s" "$ENCODED_TOKEN" > "$TOKEN_FILE"
chown "$ORIGINAL_USER":"$ORIGINAL_USER" "$TOKEN_FILE"
chmod 600 "$TOKEN_FILE"
echo "✅ Token encoded in Base64 and saved to: $TOKEN_FILE"

# -----------------------------------------------------------------------------
# 5) Configure gh with the provided username
# -----------------------------------------------------------------------------
sudo -u "$ORIGINAL_USER" gh config set user "$GITHUB_USER" &> /dev/null || true
echo "✅ Set GitHub CLI user to: $GITHUB_USER"

# -----------------------------------------------------------------------------
# Done
# -----------------------------------------------------------------------------
echo -e "\n🎉 Installation and setup complete!"
echo "   • Git and GitHub CLI are ready to use."
echo "   • Token is stored securely (Base64-encoded) in: $TOKEN_FILE"
echo "   • You may now run 'gh repo list' or other gh commands."
echo

