#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# git-wrapper.sh – NEOMNIA™ Secure GitHub Backup & Release Helper
# Version: 1.0.0
# -----------------------------------------------------------------------------
# MIT License
# Copyright (c) 2025 Charles VDD
# -----------------------------------------------------------------------------

set -euo pipefail

# ======================  CONFIGURABLE  =======================================
BACKUP_DIR="/var/backups/github"              # dossier de sauvegarde
WRAPPER_REPO="charlesvdd/administrator-neomnia" # repo du wrapper pour les releases
DEFAULT_BUMP="patch"                           # bump par défaut si --release sans --bump
# =============================================================================

# -----------------------  ASCII BANNER  --------------------------------------
cat <<'EOF'
NEOMNIA: ███╗   ██╗███████╗ ██████╗ ███╗   ███╗███╗   ██╗██╗ █████╗
NEOMNIA: ████╗  ██║██╔════╝██╔═══██╗████╗ ████║████╗  ██║██║██╔══██╗
NEOMNIA: ██╔██╗ ██║█████╗  ██║   ██║██╔████╔██║██╔██╗ ██║██║███████║
NEOMNIA: ██║╚██╗██║██╔══╝  ██║   ██║██║╚██╔╝██║██║╚██╗██║██║██╔══██║
NEOMNIA: ██║ ╚████║███████╗╚██████╔╝██║ ╚═╝ ██║██║ ╚████║██║██║  ██║
NEOMNIA: ╚═╝  ╚═══╝╚══════╝ ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝
EOF
printf "NEOMNIA: Git‑Wrapper initialisation (v%s)\n\n" "${VERSION:-1.0.0}"

# -----------------------  ROOT PRIVILEGES  -----------------------------------
if [[ $EUID -ne 0 ]]; then
  echo "NEOMNIA: 🔄 Re-executing as root…"
  exec sudo bash "$0" "$@"
fi

ORIGINAL_USER="${SUDO_USER:-$(id -un)}"
USER_HOME=$(eval echo "~$ORIGINAL_USER")

# -----------------------  INSTALL DEPENDENCIES  -----------------------------
install_pkg() {
  apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y "$@"
}

command -v git >/dev/null 2>&1 || { echo "NEOMNIA: Installing git…"; install_pkg git; }
command -v gh  >/dev/null 2>&1 || {
  echo "NEOMNIA: Installing GitHub CLI (gh)…";
  install_pkg curl gnupg;
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
  chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list
  install_pkg gh
}

echo "NEOMNIA: ✅ git & gh prêts"

# -----------------------  AUTHENTICATION  -------------------------------------
if ! gh auth status &>/dev/null; then
  echo "NEOMNIA: 🔐 Authentification à GitHub CLI… (GH_TOKEN si défini sinon prompt)"
  if [[ -n "${GH_TOKEN:-}" ]]; then
    echo "$GH_TOKEN" | gh auth login --with-token >/dev/null
  else
    gh auth login
  fi
fi

echo "NEOMNIA: ✅ Authentifié en tant que $(gh api user --jq '.login')"

# -----------------------  OPTIONS PARSING  -----------------------------------
CREATE_RELEASE=false
BUMP="" # major|minor|patch
VERSION_TAG=""

while [[ $# -gt 0 && $1 == --* ]]; do
  case $1 in
    --release) CREATE_RELEASE=true ; shift ;;
    --bump)    BUMP=$2 ; shift 2 ;;
    --version) VERSION_TAG=$2 ; shift 2 ;;
    *) break ;;
  esac
done

if [[ $CREATE_RELEASE == true && -z $VERSION_TAG && -z $BUMP ]]; then
  BUMP=$DEFAULT_BUMP
fi

# -----------------------  BACKUP LOGIC  --------------------------------------
if [[ $# -lt 1 ]]; then
  echo "NEOMNIA: Usage: $0 [--release] [--bump major|minor|patch|none] [--version x.y.z] owner/repo [owner2/repo2 …]"
  exit 1
fi

mkdir -p "$BACKUP_DIR"

for REPO in "$@"; do
  TARGET="$BACKUP_DIR/$(basename "$REPO")"
  echo "NEOMNIA: 📦 $REPO → $TARGET"
  if [[ -d "$TARGET/.git" ]]; then
    echo "NEOMNIA: ↪️  Pulling updates…"
    git -C "$TARGET" pull --ff-only
  else
    echo "NEOMNIA: ⬇️  Cloning…"
    gh repo clone "$REPO" "$TARGET"
  fi
done

chown -R "$ORIGINAL_USER":"$ORIGINAL_USER" "$BACKUP_DIR"
chmod -R 770 "$BACKUP_DIR"

echo "NEOMNIA: ✅ Backups terminés dans $BACKUP_DIR"

# -----------------------  RELEASE SECTION  -----------------------------------
if [[ $CREATE_RELEASE == true ]]; then
  echo "NEOMNIA: 🔄 Publication d'une nouvelle version du wrapper…"
  CURRENT_TAG=$(gh release list --repo "$WRAPPER_REPO" --limit 1 --json tagName --jq '.[0].tagName' || echo "v0.0.0")
  [[ $CURRENT_TAG =~ ^v?([0-9]+)\.([0-9]+)\.([0-9]+)$ ]] && {
    MAJOR=${BASH_REMATCH[1]} ; MINOR=${BASH_REMATCH[2]} ; PATCH=${BASH_REMATCH[3]}
  } || { MAJOR=0; MINOR=0; PATCH=0; }

  if [[ -n $VERSION_TAG ]]; then
    NEW_TAG="v$VERSION_TAG"
  else
    case "$BUMP" in
      major) ((MAJOR++)); MINOR=0; PATCH=0 ;;
      minor) ((MINOR++)); PATCH=0           ;;
      patch|*) ((PATCH++))                  ;;
    esac
    NEW_TAG="v$MAJOR.$MINOR.$PATCH"
  fi

  echo "NEOMNIA: Création du tag $NEW_TAG sur $WRAPPER_REPO…"
  gh release create "$NEW_TAG" --repo "$WRAPPER_REPO" --generate-notes
  echo "NEOMNIA: ✅ Release $NEW_TAG publiée !"
fi
