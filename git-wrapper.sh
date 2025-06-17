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
# THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# -----------------------------------------------------------------------------

set -euo pipefail

# -----------------------------------------------------------------------------
# NEOMNIA ASCII Banner
# -----------------------------------------------------------------------------
echo -e "NEOMNIA: ███╗   ██╗███████╗ ██████╗ ███╗   ███╗███╗   ██╗██╗ █████╗"
echo -e "NEOMNIA: ████╗  ██║██╔════╝██╔═══██╗████╗ ████║████╗  ██║██║██╔══██╗"
echo -e "NEOMNIA: ██╔██╗ ██║█████╗  ██║   ██║██╔████╔██║██╔██╗ ██║██║███████║"
echo -e "NEOMNIA: ██║╚██╗██║██╔══╝  ██║   ██║██║╚██╔╝██║██║╚██╗██║██║██╔══██║"
echo -e "NEOMNIA: ██║ ╚████║███████╗╚██████╔╝██║ ╚═╝ ██║██║ ╚████║██║██║  ██║"
echo -e "NEOMNIA: ╚═╝  ╚═══╝╚══════╝ ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝"
echo -e "NEOMNIA: Backup Script Initialisation"
echo

# URL for relaunching the script when piping\ nreadonly SCRIPT_URL="https://raw.githubusercontent.com/charlesvdd/administrator-neomnia/api-key-github/git-wrapper.sh"

# Elevate to root if not already
if [ "$EUID" -ne 0 ]; then
  echo "NEOMNIA: 🔄 Relaunching script as root..."
  base0=$(basename "$0")
  if [ -f "$0" ] && [[ "$base0" != "bash" && "$base0" != "sh" ]]; then
    exec sudo bash "$0" "$@"
  else
    exec sudo bash -c "curl -sL $SCRIPT_URL | bash"
  fi
fi

echo "NEOMNIA: Running as root"

# Now running as root
ORIGINAL_USER="${SUDO_USER:-$(id -un)}"
USER_HOME=$(eval echo "~$ORIGINAL_USER")

echo "NEOMNIA: Original user detected as $ORIGINAL_USER"

# ----------------------------------------------------------------------------
# 1) Install Git if missing
# ----------------------------------------------------------------------------
if ! command -v git &> /dev/null; then
  echo "NEOMNIA: 🔄 Git not found. Installing Git..."
  if command -v apt-get &> /dev/null; then
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y git
  elif command -v yum &> /dev/null; then
    yum install -y git
  else
    echo "NEOMNIA: ❌ No supported package manager found. Please install Git manually."
    exit 1
  fi
  echo "NEOMNIA: ✅ Git installed successfully."
else
  echo "NEOMNIA: ✅ Git is already installed."
fi

# ----------------------------------------------------------------------------
# 2) Install GitHub CLI (gh) if missing
# ----------------------------------------------------------------------------
if ! command -v gh &> /dev/null; then
  echo "NEOMNIA: 🔄 GitHub CLI (gh) not found. Installing gh..."
  if command -v apt-get &> /dev/null; then
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
      dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
      https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y gh
  elif command -v yum &> /dev/null; then
    yum install -y https://github.com/cli/cli/releases/download/v2.46.0/gh_2.46.0_linux_amd64.rpm
  else
    echo "NEOMNIA: ❌ No supported package manager found. Please install GitHub CLI manually."
    exit 1
  fi
  echo "NEOMNIA: ✅ GitHub CLI installed successfully."
else
  echo "NEOMNIA: ✅ GitHub CLI is already installed."
fi

# ----------------------------------------------------------------------------
# 3) Authenticate with GitHub via PAT
# ----------------------------------------------------------------------------
echo "NEOMNIA: 🔐 Starting GitHub authentication loop"
while true; do
  echo "NEOMNIA: • GitHub Username:"
  read -p "   » " GITHUB_USER
  if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    PAT="$GITHUB_TOKEN"
    echo "NEOMNIA: • PAT loaded from GITHUB_TOKEN."
  else
    read -s -p "NEOMNIA: • Personal Access Token: " PAT
    echo
  fi
  echo "NEOMNIA: • Attempting to authenticate..."
  if sudo -u "$ORIGINAL_USER" bash -c "printf '%s' \"$PAT\" | gh auth login --with-token" &> /dev/null; then
    echo "NEOMNIA: ✅ Authentication succeeded."
    break
  else
    echo "NEOMNIA: ❌ Authentication failed. Please check your credentials."
  fi
done

# ----------------------------------------------------------------------------
# 4) Save PAT securely
# ----------------------------------------------------------------------------
ENCODED_TOKEN=$(printf "%s" "$PAT" | base64)
TOKEN_FILE="$USER_HOME/.github_token"
printf "%s" "$ENCODED_TOKEN" > "$TOKEN_FILE"
chown "$ORIGINAL_USER":"$ORIGINAL_USER" "$TOKEN_FILE"
chmod 600 "$TOKEN_FILE"
echo "NEOMNIA: ✅ Token saved to $TOKEN_FILE"

# ----------------------------------------------------------------------------
# 5) Configure GitHub CLI user
# ----------------------------------------------------------------------------
sudo -u "$ORIGINAL_USER" gh config set user "$GITHUB_USER" &> /dev/null
echo "NEOMNIA: ✅ gh user set to $GITHUB_USER"

# ----------------------------------------------------------------------------
# 6) Prepare backup directory and clone/update repos
# ----------------------------------------------------------------------------
BACKUP_DIR="/var/backups/github"
echo "NEOMNIA: Creating backup directory at $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
chown "$ORIGINAL_USER":"$ORIGINAL_USER" "$BACKUP_DIR"
chmod 770 "$BACKUP_DIR"
echo "NEOMNIA: ✅ Backup directory ready"

echo "NEOMNIA: 🔄 Cloning/updating repositories"
sudo -u "$ORIGINAL_USER" gh repo list "$GITHUB_USER" --limit 1000 | \
while read -r repo _; do
  target="$BACKUP_DIR/$(basename "$repo")"
  if [ -d "$target/.git" ]; then
    echo "NEOMNIA: • Pulling updates for $repo"
    git -C "$target" pull --ff-only
  else
    echo "NEOMNIA: • Cloning $repo"
    gh repo clone "$repo" "$target"
  fi
done

# Fix ownership after operations
chown -R "$ORIGINAL_USER":"$ORIGINAL_USER" "$BACKUP_DIR"
echo "NEOMNIA: ✅ Repositories updated in $BACKUP_DIR"

# ----------------------------------------------------------------------------
# Done
# ----------------------------------------------------------------------------
echo

echo "NEOMNIA: 🎉 Setup complete! Git, gh et backup prêts à l’emploi."
