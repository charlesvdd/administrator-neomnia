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

# Elevate to root if not already
if [ "$EUID" -ne 0 ]; then
  echo "NEOMNIA: 🔄 Relaunching script as root..."
  exec sudo bash "$0" "$@"
fi

echo "NEOMNIA: Running as root"

ORIGINAL_USER="${SUDO_USER:-$(id -un)}"
USER_HOME=$(eval echo "~$ORIGINAL_USER")
echo "NEOMNIA: Original user detected as $ORIGINAL_USER"

# ----------------------------------------------------------------------------
# Install Git & GitHub CLI if missing
# ----------------------------------------------------------------------------
command -v git  &> /dev/null || { echo "NEOMNIA: 🔄 Installing git..."; apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y git; }
command -v gh   &> /dev/null || { echo "NEOMNIA: 🔄 Installing gh..."; apt-get install -y curl && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list && apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y gh; }
echo "NEOMNIA: ✅ git & gh ready"

# ----------------------------------------------------------------------------
# Authenticate with GitHub
# ----------------------------------------------------------------------------
echo "NEOMNIA: 🔐 Authenticate GitHub CLI"
if [[ -z "${GITHUB_TOKEN:-}" ]]; then
  gh auth login
else
  echo "$GITHUB_TOKEN" | gh auth login --with-token
fi

echo "NEOMNIA: ✅ Authenticated as $(gh auth status --hostname github.com | grep Username)"

# ----------------------------------------------------------------------------
# Prepare backup directory
# ----------------------------------------------------------------------------
BACKUP_DIR="/var/backups/github"
echo "NEOMNIA: Setting up $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
chown "$ORIGINAL_USER":"$ORIGINAL_USER" "$BACKUP_DIR"
chmod 770 "$BACKUP_DIR"

echo "NEOMNIA: ✅ Backup directory ready"

# ----------------------------------------------------------------------------
# Clone or update a single repository
# ----------------------------------------------------------------------------
if [ "$#" -lt 1 ]; then
  echo "NEOMNIA: Usage: $0 owner/repo"
  exit 1
fi
do
  REPO="$1"
  TARGET="$BACKUP_DIR/$(basename "$REPO")"
  echo "NEOMNIA: Processing $REPO"
  if [ -d "$TARGET/.git" ]; then
    echo "NEOMNIA: • Pulling updates"
    git -C "$TARGET" pull --ff-only
  else
    echo "NEOMNIA: • Cloning"
    gh repo clone "$REPO" "$TARGET"
  fi
  shift
finished

# Fix permissions recursively
chown -R "$ORIGINAL_USER":"$ORIGINAL_USER" "$BACKUP_DIR"
chmod -R 770 "$BACKUP_DIR"

echo "NEOMNIA: ✅ Done! Repository(ies) are in $BACKUP_DIR"
