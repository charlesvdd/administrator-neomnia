#!/usr/bin/env bash
set -euo pipefail

# =============================================
#  Neomia Studio - Script de connexion GitHub
#  Licence : Charles Van den driessche
# =============================================

# Couleurs
C_NEOMIA="\033[1;35m"
C_RESET="\033[0m"
C_CYAN="\033[1;36m"
C_YELLOW="\033[1;33m"
C_GREEN="\033[1;32m"
C_RED="\033[1;31m"

# Helpers
neomia_say() { echo -e "\n${C_NEOMIA}[Neomia]${C_RESET} ${C_CYAN}$*${C_RESET}"; }
neomia_warn() { echo -e "\n${C_NEOMIA}[Neomia]${C_RESET} ${C_YELLOW}⚠ $*${C_RESET}" >&2; }
neomia_err() { echo -e "\n${C_NEOMIA}[Neomia]${C_RESET} ${C_RED}✖ $*${C_RESET}" >&2; exit 1; }
neomia_ok() { echo -e "\n${C_NEOMIA}[Neomia]${C_RESET} ${C_GREEN}✔ $*${C_RESET}"; }

# Paramètres
GH_EMAIL=${GH_EMAIL:-"dev@neomnia.net"}
KEY_NAME=${KEY_NAME:-"github_ed25519"}
SSH_KEY_PATH=${SSH_KEY_PATH:-"$HOME/.ssh/$KEY_NAME"}

# Vérifie si une commande existe
need() { command -v "$1" >/dev/null 2>&1; }

install_deps() {
  neomia_say "Installation des dépendances..."
  if need apt; then
    sudo apt update -y
    sudo apt install -y git openssh-client ca-certificates curl gnupg
    if ! need gh; then
      neomia_say "Installation de GitHub CLI..."
      curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
      sudo apt update -y && sudo apt install -y gh
    fi
  else
    neomia_warn "Installez manuellement: git, openssh-client, gh (https://cli.github.com)"
  fi
}

ensure_ssh_config() {
  neomia_say "Configuration SSH..."
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"

  if [ ! -f "$SSH_KEY_PATH" ]; then
    neomia_say "Génération de la clé SSH: $SSH_KEY_PATH"
    ssh-keygen -t ed25519 -C "$GH_EMAIL" -f "$SSH_KEY_PATH" -N ""
  fi

  if ! grep -q "^Host github.com" "$HOME/.ssh/config" 2>/dev/null; then
    neomia_say "Configuration de ~/.ssh/config"
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
  neomia_ok "SSH configuré."
}

ensure_gh_login() {
  if gh auth status >/dev/null 2>&1; then
    neomia_ok "GitHub CLI déjà authentifié."
    return
  fi

  if [ -n "${GH_TOKEN:-}" ]; then
    neomia_say "Authentification avec GH_TOKEN..."
    echo "$GH_TOKEN" | gh auth login --with-token
  else
    neomia_say "Authentification interactive requise..."
    gh auth login
  fi

  if ! gh auth status >/dev/null 2>&1; then
    neomia_err "Échec de l'authentification GitHub CLI."
  fi
}

mode_ssh_account_key() {
  neomia_say "Mode: Clé SSH compte (accès global)"
  ensure_ssh_config
  ensure_gh_login

  if gh auth status >/dev/null 2>&1; then
    local title="vps-$(hostname)-$(date +%F)"
    if ! gh ssh-key add "${SSH_KEY_PATH}.pub" -t "$title"; then
      neomia_warn "Ajoutez manuellement la clé dans GitHub > Settings > SSH Keys"
      cat "$SSH_KEY_PATH.pub"
    fi
  fi

  neomia_say "Test de connexion SSH..."
  ssh -T git@github.com || true
}

mode_ssh_deploy_key() {
  neomia_say "Mode: Deploy Key (accès repo spécifique)"
  read -rp "$(echo -e "${C_NEOMIA}[Neomia]${C_RESET} ${C_CYAN}Slug du dépôt (ex: org/repo): ${C_RESET}")" REPO_SLUG
  [ -z "$REPO_SLUG" ] && neomia_err "Slug requis."

  ensure_ssh_config
  ensure_gh_login

  local title="deploy-$(hostname)-$(date +%F)"
  if ! gh repo deploy-key add "${SSH_KEY_PATH}.pub" --repo "$REPO_SLUG" -t "$title" --allow-write; then
    neomia_warn "Échec. Vérifiez les droits admin sur $REPO_SLUG"
  fi

  neomia_say "Test SSH..."
  ssh -T git@github.com || true
}

mode_https_pat() {
  neomia_say "Mode: HTTPS + PAT"
  ensure_gh_login
  gh auth setup-git
  neomia_ok "Credential helper configuré."
}

show_menu() {
  echo -e "\n${C_NEOMIA}┌───────────────────────────────────────────┐${C_RESET}"
  echo -e "${C_NEOMIA}│          Neomia Studio - Menu             │${C_RESET}"
  echo -e "${C_NEOMIA}└───────────────────────────────────────────┘${C_RESET}"
  echo -e "${C_CYAN}  [1]${C_RESET} SSH - Clé compte (accès global)"
  echo -e "${C_CYAN}  [2]${C_RESET} SSH - Deploy Key (accès repo)"
  echo -e "${C_CYAN}  [3]${C_RESET} HTTPS + PAT${C_RESET}"
  read -rp "$(echo -e "${C_NEOMIA}[Neomia]${C_RESET} ${C_CYAN}Votre choix [1-3]: ${C_RESET}")" choice

  case "$choice" in
    1) mode_ssh_account_key ;;
    2) mode_ssh_deploy_key ;;
    3) mode_https_pat ;;
    *) neomia_warn "Choix invalide. Mode 1 sélectionné."; mode_ssh_account_key ;;
  esac
}

main() {
  neomia_say "Début de la configuration GitHub"
  neomia_say "Licence: Charles Van den driessche"
  install_deps
  show_menu
  neomia_ok "Configuration terminée.
Utilisez:
  ${C_CYAN}ssh -T git@github.com${C_RESET}   # Test SSH
  ${C_CYAN}gh auth status${C_RESET}          # Vérifier l'auth"
}

main
