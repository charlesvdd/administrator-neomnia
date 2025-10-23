#!/usr/bin/env bash
set -euo pipefail

# ========== CONSTANTES GRAPHIQUES ==========
NEOMIA="${MAGENTA}⚡ Neomia${RESET}"
MAGENTA='\033[0;35m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'
CHECK="${GREEN}✓${RESET}"
CROSS="${RED}✗${RESET}"
INFO="${BLUE}ℹ${RESET}"

# ========== BANNIÈRE NEOMIA ==========
print_banner() {
  clear
  echo -e "${MAGENTA}${BOLD}"
  cat << 'EOF'
  _   _ _____ _____ _____ ____  _   _
 | \ | |_   _|_   _|_   _|  _ \| | | |
 |  \| | | |   | |   | | | |_) | | | |
 | |\  | | |   | |   | | |  __/| |_| |
 |_| \_| |_|   |_|   |_| |_|    \___/
   🚀  NEOMIA GIT SETUP — POWERED BY NEOMIA STUDIO  🚀
EOF
  echo -e "${RESET}"
}

# ========== PARAMÈTRES CONFIGURABLES ==========
USE_SSH=${USE_SSH:-1}                     # 1=SSH, 0=HTTPS+PAT
GH_USERNAME="${GH_USERNAME:-neosaastech}" # Org/user GitHub
GH_EMAIL="${GH_EMAIL:-you@example.com}"   # Email pour la clé SSH
CLONE_DIR="${CLONE_DIR:-/opt/neosaas-dev}"
REPO_SSH="git@github.com:neosaastech/neosaas-dev.git"
REPO_HTTPS="https://github.com/neosaastech/neosaas-dev.git"

# ========== FONCTIONS UTILITAIRES ==========
# Barre de progression
progress_bar() {
  local duration=${1}
  local columns=$(tput cols)
  local space=$((columns - 8))
  local bar_size=$((space - 4))
  local elapsed=0
  while [ $elapsed -lt $duration ]; do
    local filled=$((elapsed * bar_size / duration))
    printf "\r${NEOMIA} ["
    printf "%${filled}s" | tr ' ' '='
    printf "%$((bar_size - filled))s" | tr ' ' ' '
    printf "] %3d%%%%" $((elapsed * 100 / duration))
    sleep 0.05
    elapsed=$((elapsed + 1))
  done
  printf "\r${NEOMIA} ["
  printf "%${bar_size}s" | tr ' ' '='
  printf "] 100%%%%\n"
}

# Vérification des droits sudo
check_sudo() {
  if ! sudo -v; then
    echo -e "${RED}${CROSS} ${NEOMIA} Erreur : droits sudo requis pour installer les dépendances.${RESET}"
    exit 1
  fi
}

# Installation des dépendances (multi-OS)
install_dependencies() {
  echo -e "${NEOMIA} ${DIM}→ Installation des dépendances système...${RESET}"
  if command -v apt >/dev/null; then
    sudo apt update -y >/dev/null 2>&1 &
    progress_bar 5
    sudo apt install -y curl git ca-certificates gnupg openssh-client >/dev/null 2>&1 &
    progress_bar 10
  elif command -v dnf >/dev/null; then
    sudo dnf install -y curl git gnupg2 openssh-clients >/dev/null 2>&1 &
    progress_bar 10
  elif command -v brew >/dev/null; then
    brew install curl git gnupg openssh >/dev/null 2>&1 &
    progress_bar 10
  else
    echo -e "${RED}${CROSS} ${NEOMIA} OS non supporté pour l'installation automatique.${RESET}"
    exit 1
  fi
  echo -e "${GREEN}${CHECK} ${NEOMIA} Dépendances système installées.${RESET}"
}

# Installation de GitHub CLI (gh)
install_gh() {
  if ! command -v gh >/dev/null; then
    echo -e "${NEOMIA} ${DIM}→ Installation de GitHub CLI (gh)...${RESET}"
    if command -v apt >/dev/null; then
      curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg >/dev/null 2>&1
      sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
      sudo apt update -y >/dev/null 2>&1 &
      progress_bar 5
      sudo apt install -y gh >/dev/null 2>&1 &
      progress_bar 10
    elif command -v dnf >/dev/null; then
      sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo >/dev/null 2>&1
      sudo dnf install -y gh >/dev/null 2>&1 &
      progress_bar 10
    elif command -v brew >/dev/null; then
      brew install gh >/dev/null 2>&1 &
      progress_bar 10
    else
      echo -e "${RED}${CROSS} ${NEOMIA} Impossible d'installer gh automatiquement.${RESET}"
      exit 1
    fi
    echo -e "${GREEN}${CHECK} ${NEOMIA} GitHub CLI (gh) installé.${RESET}"
  else
    echo -e "${GREEN}${CHECK} ${NEOMIA} GitHub CLI déjà présent.${RESET}"
  fi
}

# Authentification GitHub
ensure_gh_auth() {
  echo -e "${NEOMIA} ${DIM}→ Authentification GitHub...${RESET}"
  # Charger .env si présent
  if [ -f ".env" ]; then
    set -a; source .env; set +a
  fi

  # Saisie interactive du token si manquant en mode HTTPS
  if [[ -z "${GH_TOKEN:-}" && "$USE_SSH" == "0" ]]; then
    read -s -p "${NEOMIA} Entrez votre GH_TOKEN (masqué) : " GH_TOKEN
    echo
    export GH_TOKEN
  fi

  # Authentification via gh
  if [[ -n "${GH_TOKEN:-}" ]]; then
    echo "$GH_TOKEN" | gh auth login --with-token >/dev/null 2>&1
    unset GH_TOKEN  # Nettoyage immédiat
    export GH_TOKEN=""
    echo -e "${GREEN}${CHECK} ${NEOMIA} Authentifié via token.${RESET}"
  elif ! gh auth status >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  ${NEOMIA} Exécutez 'gh auth login' manuellement, puis relancez ce script.${RESET}"
    exit 1
  else
    echo -e "${GREEN}${CHECK} ${NEOMIA} Déjà authentifié en tant que $(gh api user --jq '.login').${RESET}"
  fi
}

# Configuration SSH
setup_ssh() {
  echo -e "${NEOMIA} ${DIM}→ Configuration SSH...${RESET}"
  KEY_PATH="${KEY_PATH:-$HOME/.ssh/github_${GH_USERNAME}_ed25519}"
  mkdir -p ~/.ssh
  chmod 700 ~/.ssh

  # Générer la clé si absente (avec confirmation)
  if [[ ! -f "$KEY_PATH" ]]; then
    read -p "${NEOMIA} Générer une nouvelle clé SSH pour $GH_USERNAME ? (o/O) " choice
    if [[ "$choice" =~ ^[oO]$ ]]; then
      echo -e "${NEOMIA} ${DIM}→ Génération de la clé SSH ed25519...${RESET}"
      ssh-keygen -t ed25519 -C "$GH_EMAIL" -f "$KEY_PATH" -N "" >/dev/null 2>&1 &
      progress_bar 5
      echo -e "${GREEN}${CHECK} ${NEOMIA} Clé SSH générée : $KEY_PATH${RESET}"
    else
      echo -e "${RED}${CROSS} ${NEOMIA} Clé SSH requise. Relancez après génération manuelle.${RESET}"
      exit 1
    fi
  else
    echo -e "${GREEN}${CHECK} ${NEOMIA} Clé SSH existante : $KEY_PATH${RESET}"
  fi

  # Config SSH
  if ! grep -q "Host github.com" ~/.ssh/config 2>/dev/null; then
    echo -e "${NEOMIA} ${DIM}→ Configuration de ~/.ssh/config...${RESET}"
    cat >> ~/.ssh/config <<EOF
Host github.com
  HostName github.com
  User git
  IdentityFile $KEY_PATH
  IdentitiesOnly yes
EOF
    chmod 600 ~/.ssh/config
    echo -e "${GREEN}${CHECK} ${NEOMIA} Configuration SSH mise à jour.${RESET}"
  fi

  # Ajouter la clé à l'agent SSH
  eval "$(ssh-agent -s)" >/dev/null
  ssh-add "$KEY_PATH" >/dev/null 2>&1
  echo -e "${GREEN}${CHECK} ${NEOMIA} Clé ajoutée à l'agent SSH.${RESET}"

  # Vérifier la connexion SSH
  echo -e "${NEOMIA} ${DIM}→ Test de connexion SSH...${RESET}"
  if ! ssh -T git@github.com 2>/dev/null | grep -q "successfully authenticated"; then
    echo -e "${RED}${CROSS} ${NEOMIA} Échec de l'authentification SSH.${RESET}"
    exit 1
  else
    echo -e "${GREEN}${CHECK} ${NEOMIA} Connexion SSH réussie.${RESET}"
  fi

  # Ajouter la clé à GitHub (si GH_TOKEN fourni)
  if [[ -n "${GH_TOKEN:-}" ]]; then
    if ! gh ssh-key list | grep -q "$(cat "${KEY_PATH}.pub" | awk '{print $3}')"; then
      echo -e "${NEOMIA} ${DIM}→ Ajout de la clé SSH à GitHub...${RESET}"
      gh ssh-key add "${KEY_PATH}.pub" -t "vps-$(hostname)-$(date +%F)" >/dev/null 2>&1 &
      progress_bar 3
      echo -e "${GREEN}${CHECK} ${NEOMIA} Clé SSH ajoutée à GitHub.${RESET}"
    else
      echo -e "${GREEN}${CHECK} ${NEOMIA} Clé SSH déjà présente sur GitHub.${RESET}"
    fi
  else
    echo -e "${YELLOW}⚠️  ${NEOMIA} Ajoutez manuellement la clé publique à GitHub : ${KEY_PATH}.pub${RESET}"
  fi
}

# Clone du dépôt
clone_repo() {
  echo -e "${NEOMIA} ${DIM}→ Clone du dépôt...${RESET}"
  mkdir -p "$(dirname "$CLONE_DIR")"
  if [[ ! -d "$CLONE_DIR/.git" ]]; then
    if [[ "$USE_SSH" == "1" ]]; then
      git clone "$REPO_SSH" "$CLONE_DIR" >/dev/null 2>&1 &
      progress_bar 15
    else
      git clone "$REPO_HTTPS" "$CLONE_DIR" >/dev/null 2>&1 &
      progress_bar 15
    fi
    echo -e "${GREEN}${CHECK} ${NEOMIA} Dépôt cloné dans $CLONE_DIR.${RESET}"
  else
    echo -e "${GREEN}${CHECK} ${NEOMIA} Dépôt déjà présent : $CLONE_DIR${RESET}"
  fi
}

# ========== FLUX PRINCIPAL ==========
print_banner
check_sudo
install_dependencies
install_gh
ensure_gh_auth

if [[ "$USE_SSH" == "1" ]]; then
  setup_ssh
else
  echo -e "${NEOMIA} ${DIM}→ Configuration de Git pour HTTPS...${RESET}"
  gh auth setup-git >/dev/null 2>&1 &
  progress_bar 5
  echo -e "${GREEN}${CHECK} ${NEOMIA} Git configuré pour utiliser gh comme credential helper.${RESET}"
fi

clone_repo
echo -e "\n${NEOMIA} ${BOLD}✅ Configuration terminée !${RESET}"
echo -e "${NEOMIA} Dossier du projet : ${BOLD}$CLONE_DIR${RESET}"
echo -e "${NEOMIA} Pour commencer :"
echo -e "  ${BOLD}cd $CLONE_DIR${RESET}"
echo -e "  ${BOLD}git status${RESET}\n"
