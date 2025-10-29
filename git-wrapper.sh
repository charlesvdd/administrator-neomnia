#!/usr/bin/env bash
set -euo pipefail

# =============================================
#  Neomia Studio - Script de connexion GitHub
#  Licence : Charles Van den driessche
#  Objectif : Configurer la connexion GitHub sur le serveur
# =============================================

# =========================
#  Paramètres par défaut
# =========================
: "${GH_EMAIL:=dev@neomnia.net}"         # Utilisé comme commentaire pour la clé SSH
: "${KEY_NAME:=github_ed25519}"          # Nom du fichier de clé dans ~/.ssh
: "${SSH_KEY_PATH:=$HOME/.ssh/${KEY_NAME}"

# =========================
#  Helpers (avec style Neomia)
# =========================
neomia_say() { printf "\n\033[1;35m[Neomia]\033[0m \033[1;36m%s\033[0m\n" "$*"; }
neomia_warn() { printf "\n\033[1;35m[Neomia]\033[0m \033[1;33m⚠ %s\033[0m\n" "$*"; }
neomia_err() { printf "\n\033[1;35m[Neomia]\033[0m \033[1;31m✖ %s\033[0m\n" "$*" >&2; exit 1; }
neomia_ok() { printf "\n\033[1;35m[Neomia]\033[0m \033[1;32m✔ %s\033[0m\n" "$*"; }
neomia_need() { command -v "$1" >/dev/null 2>&1; }

install_deps() {
  neomia_say "Installation des dépendances (git, openssh-client, gh)..."
  if neomia_need apt; then
    sudo apt update -y
    sudo apt install -y git openssh-client ca-certificates curl gnupg
    if ! neomia_need gh; then
      neomia_say "Installation de GitHub CLI..."
      curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
      sudo apt update -y && sudo apt install -y gh
    fi
  else
    neomia_warn "Distribution non-apt détectée. Installe manuellement: git, openssh-client, gh."
  fi
}

ensure_ssh_config() {
  neomia_say "Configuration SSH en cours..."
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  if [[ ! -f "$SSH_KEY_PATH" ]]; then
    neomia_say "Génération d'une clé SSH ed25519: $SSH_KEY_PATH"
    ssh-keygen -t ed25519 -C "$GH_EMAIL" -f "$SSH_KEY_PATH" -N ""
  else
    neomia_say "Clé SSH déjà présente: $SSH_KEY_PATH"
  fi
  if ! grep -q "^Host github.com" "$HOME/.ssh/config" 2>/dev/null; then
    neomia_say "Ajout de la config SSH pour github.com"
    cat >>"$HOME/.ssh/config" <<'EOF'
Host github.com
  HostName github.com
  User git
  IdentityFile ${SSH_KEY_PATH}
  IdentitiesOnly yes
EOF
    chmod 600 "$HOME/.ssh/config"
  fi
  eval "$(ssh-agent -s)" >/dev/null
  ssh-add "$SSH_KEY_PATH" >/dev/null
  neomia_ok "Configuration SSH terminée."
}

ensure_gh_login() {
  if gh auth status >/dev/null 2>&1; then
    neomia_ok "GitHub CLI déjà authentifié."
    return
  fi
  if [[ -n "${GH_TOKEN:-}" ]]; then
    neomia_say "Authentification gh via GH_TOKEN (non interactif)"
    echo "$GH_TOKEN" | gh auth login --with-token
  else
    neomia_say "Ouverture d'une authentification gh interactive..."
    gh auth login
  fi
  if ! gh auth status >/dev/null 2>&1; then
    neomia_err "Échec d'authentification GitHub CLI."
  fi
}

mode_ssh_account_key() {
  neomia_say "Mode : Clé SSH liée au COMPTE GitHub (accès global)"
  ensure_ssh_config
  ensure_gh_login
  neomia_say "Ajout de la clé publique au COMPTE GitHub (SSH Keys du profil)"
  if gh auth status >/dev/null 2>&1; then
    local title="vps-$(hostname)-$(date +%F)"
    if ! gh ssh-key add "${SSH_KEY_PATH}.pub" -t "$title"; then
      neomia_warn "Impossible d'ajouter automatiquement la clé. Ajoute-la manuellement dans GitHub > Settings > SSH and GPG keys."
    fi
  else
    neomia_warn "gh non authentifié. Ajoute manuellement la clé publique : ${SSH_KEY_PATH}.pub"
  fi
  neomia_say "Test SSH → github.com"
  ssh -T git@github.com || true
}

mode_ssh_deploy_key() {
  neomia_say "Mode : Clé SSH Deploy Key (accès limité à un repo)"
  local REPO_SLUG=""
  printf "\033[1;35m[Neomia]\033[0m \033[1;36mEntrez le slug du dépôt (ex: neosaastech/neosaas-dev) : \033[0m"
  read -r REPO_SLUG
  if [[ -z "$REPO_SLUG" ]]; then
    neomia_err "Slug de dépôt requis."
  fi
  ensure_ssh_config
  ensure_gh_login
  neomia_say "Ajout de la clé publique comme DEPLOY KEY sur ${REPO_SLUG}"
  local title="deploy-$(hostname)-$(date +%F)"
  if ! gh repo deploy-key add "${SSH_KEY_PATH}.pub" --repo "${REPO_SLUG}" -t "$title" --allow-write; then
    neomia_warn "Échec de l'ajout deploy-key. Vérifiez les droits maintainer/admin sur ${REPO_SLUG}."
  fi
  neomia_say "Test SSH → github.com"
  ssh -T git@github.com || true
}

mode_https_pat() {
  neomia_say "Mode : HTTPS + PAT via GitHub CLI"
  ensure_gh_login
  neomia_say "Configuration du credential helper git via gh"
  gh auth setup-git
}

menu() {
  echo
  echo -e "\033[1;35m┌───────────────────────────────────────────┐\033[0m"
  echo -e "\033[1;35m│       Neomia Studio - Menu               │\033[0m"
  echo -e "\033[1;35m└───────────────────────────────────────────┘\033[0m"
  echo
  echo -e "\033[1;36m  [1]\033[0m SSH - Clé liée au COMPTE GitHub (accès global)"
  echo -e "\033[1;36m  [2]\033[0m SSH - Deploy Key liée à un REPO spécifique"
  echo -e "\033[1;36m  [3]\033[0m HTTPS + PAT via GitHub CLI"
  echo
  printf "\033[1;35m[Neomia]\033[0m \033[1;36mTon choix [1/2/3] : \033[0m"
  read -r choice
  case "${choice:-1}" in
    1) mode_ssh_account_key ;;
    2) mode_ssh_deploy_key ;;
    3) mode_https_pat ;;
    *) neomia_warn "Choix invalide, on utilise [1] par défaut."; mode_ssh_account_key ;;
  esac
}

# =========================
#  MAIN
# =========================
neomia_say "Lancement de la configuration GitHub pour Neomia Studio"
neomia_say "Licence : Charles Van den driessche"
install_deps
menu
neomia_ok "Configuration terminée.
Utilisez \033[1;36mgit\033[0m ou \033[1;36mgh\033[0m pour interagir avec GitHub.

Astuces :
  \033[1;36mssh -T git@github.com\033[0m   # Test SSH
  \033[1;36mgh auth status\033[0m         # Statut d'authentification"
