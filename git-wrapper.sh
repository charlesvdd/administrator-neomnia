#!/usr/bin/env bash
set -euo pipefail

# ========== COULEURS & STYLE ==========
MAGENTA='\033[0;35m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'
NEOMIA="${MAGENTA}⚡ Neomia${RESET}"
CHECK="${GREEN}✓${RESET}"
CROSS="${RED}✗${RESET}"
INFO="${BLUE}ℹ${RESET}"

# ========== BANNIÈRE ==========
print_banner() {
  echo -e "${MAGENTA}${BOLD}"
  cat << 'EOF'
  _   _ _____ _____ _____ ____  _   _
 | \ | |_   _|_   _|_   _|  _ \| | | |
 |  \| | | |   | |   | | | |_) | | | |
 | |\  | | |   | |   | | |  __/| |_| |
 |_| \_| |_|   |_|   |_| |_|    \___/
   🚀  NEOMIA GIT SETUP — GITHUB CLI ONLY  🚀
EOF
  echo -e "${RESET}"
}

# ========== PARAMÈTRES ==========
GH_USERNAME="${GH_USERNAME:-neosaastech}"  # Votre utilisateur/organisation GitHub
REPO_HTTPS="https://github.com/${GH_USERNAME}/neosaas-dev.git"  # Remplacez par votre repo
CLONE_DIR="${CLONE_DIR:-/opt/neosaas-dev}"  # Dossier de destination

# ========== INSTALLATION DES DÉPENDANCES ==========
install_dependencies() {
  echo -e "${NEOMIA} ${DIM}→ Installation des dépendances...${RESET}"
  if ! command -v git &>/dev/null; then
    sudo apt update -y && sudo apt install -y git curl ca-certificates
  fi
  if ! command -v gh &>/dev/null; then
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
    sudo apt update -y && sudo apt install -y gh
  fi
  echo -e "${GREEN}${CHECK} ${NEOMIA} Dépendances installées.${RESET}"
}

# ========== AUTHENTIFICATION GITHUB ==========
authenticate_github() {
  echo -e "${NEOMIA} ${DIM}→ Authentification GitHub...${RESET}"

  # Charger .env si présent
  if [ -f ".env" ]; then
    set -a; source .env; set +a
  fi

  # Saisie interactive du token si manquant
  if [[ -z "${GH_TOKEN:-}" ]]; then
    read -s -p "${NEOMIA} Entrez votre GH_TOKEN (masqué) : " GH_TOKEN
    echo
    export GH_TOKEN
  fi

  # Authentification via gh
  echo "$GH_TOKEN" | gh auth login --with-token
  unset GH_TOKEN  # Nettoyage immédiat
  echo -e "${GREEN}${CHECK} ${NEOMIA} Authentifié en tant que $(gh api user --jq '.login').${RESET}"

  # Configurer Git pour utiliser gh comme credential helper
  gh auth setup-git
  echo -e "${GREEN}${CHECK} ${NEOMIA} Git configuré pour utiliser GitHub CLI.${RESET}"
}

# ========== CLONE DU DÉPÔT ==========
clone_repo() {
  echo -e "${NEOMIA} ${DIM}→ Clone du dépôt...${RESET}"
  mkdir -p "$(dirname "$CLONE_DIR")"
  if [[ ! -d "$CLONE_DIR/.git" ]]; then
    git clone "$REPO_HTTPS" "$CLONE_DIR"
    echo -e "${GREEN}${CHECK} ${NEOMIA} Dépôt cloné dans $CLONE_DIR.${RESET}"
  else
    echo -e "${GREEN}${CHECK} ${NEOMIA} Dépôt déjà présent : $CLONE_DIR${RESET}"
    cd "$CLONE_DIR" && git pull
  fi
}

# ========== CONFIGURATION GIT ==========
configure_git() {
  echo -e "${NEOMIA} ${DIM}→ Configuration de Git...${RESET}"
  git config --global user.name "$GH_USERNAME"
  git config --global user.email "${GH_USERNAME}@users.noreply.github.com"
  echo -e "${GREEN}${CHECK} ${NEOMIA} Git configuré.${RESET}"
}

# ========== FLUX PRINCIPAL ==========
print_banner
install_dependencies
authenticate_github
configure_git
clone_repo

echo -e "\n${NEOMIA} ${BOLD}✅ Configuration terminée !${RESET}"
echo -e "${NEOMIA} Dossier du projet : ${BOLD}$CLONE_DIR${RESET}"
echo -e "${NEOMIA} Pour commencer :"
echo -e "  ${BOLD}cd $CLONE_DIR${RESET}"
echo -e "  ${BOLD}git status${RESET}"
echo -e "\n${NEOMIA} L'authentification se fait désormais via GitHub CLI (gh).${RESET}"
echo -e "${NEOMIA} Plus besoin de SSH : les credentials sont gérés par 'gh'.${RESET}"
