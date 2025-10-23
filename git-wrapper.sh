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
   🚀  NEOMIA GIT SETUP — INTÉGRATION GITHUB CLI  🚀
EOF
  echo -e "${RESET}"
}

# ========== PARAMÈTRES ==========
GH_USERNAME="${GH_USERNAME:-neosaastech}"  # Votre utilisateur/organisation GitHub
GH_EMAIL="${GH_EMAIL:-you@example.com}"    # Email pour la clé SSH
REPO_SSH="git@github.com:${GH_USERNAME}/neosaas-dev.git"  # Remplacez par votre repo
CLONE_DIR="${CLONE_DIR:-/opt/neosaas-dev}"  # Dossier de destination

# ========== INSTALLATION DES DÉPENDANCES ==========
install_dependencies() {
  echo -e "${NEOMIA} ${DIM}→ Installation des dépendances...${RESET}"
  if ! command -v git &>/dev/null; then
    sudo apt update -y && sudo apt install -y git openssh-client curl ca-certificates
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
  if [ -f ".env" ]; then
    set -a; source .env; set +a  # Charge les variables d'environnement
  fi

  # Si GH_TOKEN est fourni, l'utiliser pour s'authentifier
  if [[ -n "${GH_TOKEN:-}" ]]; then
    echo "$GH_TOKEN" | gh auth login --with-token
    unset GH_TOKEN  # Nettoyage immédiat
    echo -e "${GREEN}${CHECK} ${NEOMIA} Authentifié via token.${RESET}"
  elif ! gh auth status &>/dev/null; then
    echo -e "${YELLOW}⚠️  ${NEOMIA} Exécutez 'gh auth login' manuellement, puis relancez ce script.${RESET}"
    exit 1
  else
    echo -e "${GREEN}${CHECK} ${NEOMIA} Déjà authentifié en tant que $(gh api user --jq '.login').${RESET}"
  fi
}

# ========== CONFIGURATION SSH ==========
setup_ssh_key() {
  echo -e "${NEOMIA} ${DIM}→ Configuration de la clé SSH...${RESET}"
  SSH_KEY_PATH="$HOME/.ssh/github_${GH_USERNAME}_ed25519"

  # Générer la clé SSH si absente
  if [[ ! -f "$SSH_KEY_PATH" ]]; then
    echo -e "${NEOMIA} ${DIM}→ Génération de la clé SSH ed25519...${RESET}"
    ssh-keygen -t ed25519 -C "$GH_EMAIL" -f "$SSH_KEY_PATH" -N "" -q
    echo -e "${GREEN}${CHECK} ${NEOMIA} Clé SSH générée : $SSH_KEY_PATH${RESET}"
  else
    echo -e "${GREEN}${CHECK} ${NEOMIA} Clé SSH existante : $SSH_KEY_PATH${RESET}"
  fi

  # Configurer SSH pour GitHub
  if ! grep -q "Host github.com" ~/.ssh/config 2>/dev/null; then
    cat >> ~/.ssh/config <<EOF
Host github.com
  HostName github.com
  User git
  IdentityFile $SSH_KEY_PATH
  IdentitiesOnly yes
EOF
    chmod 600 ~/.ssh/config
    echo -e "${GREEN}${CHECK} ${NEOMIA} Configuration SSH mise à jour.${RESET}"
  fi

  # Ajouter la clé à l'agent SSH
  eval "$(ssh-agent -s)" >/dev/null
  ssh-add "$SSH_KEY_PATH" >/dev/null 2>&1
  echo -e "${GREEN}${CHECK} ${NEOMIA} Clé ajoutée à l'agent SSH.${RESET}"

  # Tester la connexion SSH
  if ssh -T git@github.com &>/dev/null; then
    echo -e "${GREEN}${CHECK} ${NEOMIA} Connexion SSH réussie.${RESET}"
  else
    echo -e "${RED}${CROSS} ${NEOMIA} Échec de la connexion SSH. Vérifiez votre clé et réessayez.${RESET}"
    exit 1
  fi

  # Ajouter la clé à GitHub via gh CLI (si authentifié)
  if gh auth status &>/dev/null; then
    if ! gh ssh-key list | grep -q "$(ssh-keygen -lf "$SSH_KEY_PATH" | awk '{print $2}')"; then
      echo -e "${NEOMIA} ${DIM}→ Ajout de la clé SSH à GitHub...${RESET}"
      gh ssh-key add "$SSH_KEY_PATH.pub" -t "Neomia-$(hostname)-$(date +%F)"
      echo -e "${GREEN}${CHECK} ${NEOMIA} Clé SSH ajoutée à GitHub.${RESET}"
    else
      echo -e "${GREEN}${CHECK} ${NEOMIA} Clé SSH déjà présente sur GitHub.${RESET}"
    fi
  else
    echo -e "${YELLOW}⚠️  ${NEOMIA} Impossible d'ajouter la clé à GitHub : authentification requise.${RESET}"
    echo -e "${YELLOW}⚠️  ${NEOMIA} Ajoutez manuellement la clé publique : ${SSH_KEY_PATH}.pub${RESET}"
  fi
}

# ========== CLONE DU DÉPÔT ==========
clone_repo() {
  echo -e "${NEOMIA} ${DIM}→ Clone du dépôt...${RESET}"
  mkdir -p "$(dirname "$CLONE_DIR")"
  if [[ ! -d "$CLONE_DIR/.git" ]]; then
    git clone "$REPO_SSH" "$CLONE_DIR"
    echo -e "${GREEN}${CHECK} ${NEOMIA} Dépôt cloné dans $CLONE_DIR.${RESET}"
  else
    echo -e "${GREEN}${CHECK} ${NEOMIA} Dépôt déjà présent : $CLONE_DIR${RESET}"
    cd "$CLONE_DIR" && git pull
  fi
}

# ========== CONFIGURATION GIT GLOBAL ==========
configure_git() {
  echo -e "${NEOMIA} ${DIM}→ Configuration de Git...${RESET}"
  git config --global user.name "$GH_USERNAME"
  git config --global user.email "$GH_EMAIL"
  git config --global core.sshCommand "ssh -i $SSH_KEY_PATH -F /dev/null"
  echo -e "${GREEN}${CHECK} ${NEOMIA} Git configuré pour utiliser SSH.${RESET}"
}

# ========== FLUX PRINCIPAL ==========
print_banner
install_dependencies
authenticate_github
setup_ssh_key
configure_git
clone_repo

echo -e "\n${NEOMIA} ${BOLD}✅ Configuration terminée !${RESET}"
echo -e "${NEOMIA} Dossier du projet : ${BOLD}$CLONE_DIR${RESET}"
echo -e "${NEOMIA} Pour commencer :"
echo -e "  ${BOLD}cd $CLONE_DIR${RESET}"
echo -e "  ${BOLD}git status${RESET}"
echo -e "\n${NEOMIA} La clé SSH a été ajoutée à GitHub et configurée pour une utilisation transparente.${RESET}"
