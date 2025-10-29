#!/bin/bash
set -euo pipefail

# =============================================
#  Neomia Studio - Connexion GitHub
#  Licence : Charles Van den driessche
# =============================================

# Couleurs (sans parenthèses)
NEOMIA="\e[1;35m[Neomia]\e[0m"
CYAN="\e[1;36m"
YELLOW="\e[1;33m"
GREEN="\e[1;32m"
RED="\e[1;31m"
RESET="\e[0m"

log() {
  echo -e "\n${NEOMIA} ${CYAN}$1${RESET}"
}
warn() {
  echo -e "\n${NEOMIA} ${YELLOW}⚠ $1${RESET}" >&2
}
ok() {
  echo -e "\n${NEOMIA} ${GREEN}✔ $1${RESET}"
}
err() {
  echo -e "\n${NEOMIA} ${RED}✖ $1${RESET}" >&2
  exit 1
}

# Paramètres par défaut
GH_EMAIL=${GH_EMAIL:-"dev@neomnia.net"}
KEY_NAME=${KEY_NAME:-"github_ed25519"}
SSH_KEY_PATH="$HOME/.ssh/$KEY_NAME"

# Vérifie si une commande existe
has() {
  command -v "$1" >/dev/null 2>&1
}

install_deps() {
  log "Installation des dépendances..."
  if has apt; then
    sudo apt update -y
    sudo apt install -y git openssh-client ca-certificates curl gnupg
    if ! has gh; then
      log "Installation de GitHub CLI..."
      curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
      sudo apt update -y && sudo apt install -y gh
    fi
  else
    warn "Installez manuellement: git, openssh-client, gh"
  fi
}

setup_ssh() {
  log "Configuration SSH..."
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"

  if [ ! -f "$SSH_KEY_PATH" ]; then
    log "Génération de la clé SSH: $SSH_KEY_PATH"
    ssh-keygen -t ed25519 -C "$GH_EMAIL" -f "$SSH_KEY_PATH" -N ""
  fi

  if ! grep -q "Host github.com" "$HOME/.ssh/config" 2>/dev/null; then
    log "Configuration de ~/.ssh/config"
    cat >> "$HOME/.ssh/config" <<EOF
Host github.com
  HostName github.com
  User git
  IdentityFile $SSH_KEY_PATH
  IdentitiesOnly yes
EOF
    chmod 600 "$HOME/.ssh/config"
  fi

  eval "$(ssh-agent -s)" >/dev/null
  ssh-add "$SSH_KEY_PATH" >/dev/null
  ok "SSH configuré"
}

auth_github() {
  if gh auth status >/dev/null 2>&1; then
    ok "GitHub CLI déjà authentifié"
    return
  fi

  if [ -n "${GH_TOKEN:-}" ]; then
    log "Authentification avec GH_TOKEN..."
    echo "$GH_TOKEN" | gh auth login --with-token
  else
    log "Authentification interactive requise..."
    gh auth login
  fi

  if ! gh auth status >/dev/null 2>&1; then
    err "Échec de l'authentification GitHub CLI"
  fi
}

add_account_key() {
  log "Ajout de la clé SSH au compte GitHub..."
  setup_ssh
  auth_github

  if gh auth status >/dev/null 2>&1; then
    local title="vps-$(hostname)-$(date +%F)"
    if ! gh ssh-key add "${SSH_KEY_PATH}.pub" -t "$title"; then
      warn "Ajoutez manuellement la clé dans GitHub > Settings > SSH Keys"
      echo "Clé publique:"
      cat "${SSH_KEY_PATH}.pub"
    fi
  fi

  log "Test de connexion SSH..."
  ssh -T git@github.com || true
}

add_deploy_key() {
  log "Ajout d'une Deploy Key..."
  read -p "${NEOMIA} ${CYAN}Slug du dépôt (ex: org/repo): ${RESET}" REPO_SLUG
  [ -z "$REPO_SLUG" ] && err "Slug requis"

  setup_ssh
  auth_github

  local title="deploy-$(hostname)-$(date +%F)"
  if ! gh repo deploy-key add "${SSH_KEY_PATH}.pub" --repo "$REPO_SLUG" -t "$title" --allow-write; then
    warn "Échec. Vérifiez les droits admin sur $REPO_SLUG"
  fi

  log "Test SSH..."
  ssh -T git@github.com || true
}

setup_https() {
  log "Configuration HTTPS + PAT..."
  auth_github
  gh auth setup-git
  ok "Credential helper configuré"
}

show_menu() {
  echo -e "\n${NEOMIA} ${CYAN}Menu:${RESET}"
  echo "  1. SSH - Clé compte (accès global)"
  echo "  2. SSH - Deploy Key (accès repo)"
  echo "  3. HTTPS + PAT"
  read -p "${NEOMIA} ${CYAN}Votre choix [1-3]: ${RESET}" choice

  case "$choice" in
    1) add_account_key ;;
    2) add_deploy_key ;;
    3) setup_https ;;
    *) warn "Choix invalide. Mode 1 sélectionné"; add_account_key ;;
  esac
}

main() {
  log "Lancement de la configuration GitHub"
  log "Licence: Charles Van den driessche"
  install_deps
  show_menu
  ok "Configuration terminée.
Utilisez:
  ${CYAN}ssh -T git@github.com${RESET}   # Test SSH
  ${CYAN}gh auth status${RESET}          # Vérifier l'auth"
}

main
