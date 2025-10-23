#!/usr/bin/env bash
set -euo pipefail

# =========================
#  Paramètres par défaut
# =========================
: "${REPO_SLUG:=neosaastech/neosaas-dev}"
: "${CLONE_DIR:=/opt/neosaas-dev}"
: "${GH_EMAIL:=dev@neomnia.net}"         # utilisé comme commentaire pour la clé SSH
: "${KEY_NAME:=github_ed25519}"          # nom du fichier de clé dans ~/.ssh
: "${SSH_KEY_PATH:=$HOME/.ssh/${KEY_NAME}}"

# Si tu exportes GH_TOKEN (PAT) avant d'exécuter le script, il sera utilisé automatiquement
# export GH_TOKEN="ghp_xxx"

# =========================
#  Helpers
# =========================
say() { printf "\n\033[1;36m%s\033[0m\n" "$*"; }           # cyan bold
warn() { printf "\n\033[1;33m%s\033[0m\n" "⚠ $*"; }         # yellow
err() { printf "\n\033[1;31m%s\033[0m\n" "✖ $*"; exit 1; }  # red
ok() { printf "\n\033[1;32m%s\033[0m\n" "✔ $*"; }           # green

need() { command -v "$1" >/dev/null 2>&1 || return 1; }

install_deps() {
  if need apt; then
    say "Installation des dépendances (git, openssh-client, gh)..."
    sudo apt update -y
    sudo apt install -y git openssh-client ca-certificates curl gnupg

    if ! need gh; then
      curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
      sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
      sudo apt update -y && sudo apt install -y gh
    fi
  else
    warn "Distribution non-apt détectée. Installe manuellement: git, openssh-client, gh."
  fi
}

ensure_ssh_config() {
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"

  # Créer la clé si absente
  if [[ ! -f "$SSH_KEY_PATH" ]]; then
    say "Génération d'une clé SSH ed25519: $SSH_KEY_PATH"
    ssh-keygen -t ed25519 -C "$GH_EMAIL" -f "$SSH_KEY_PATH" -N ""
  else
    say "Clé SSH déjà présente: $SSH_KEY_PATH"
  fi

  # Bloque d'host GitHub dans ~/.ssh/config
  if ! grep -q "^Host github.com" "$HOME/.ssh/config" 2>/dev/null; then
    say "Ajout de la config SSH pour github.com"
    cat >>"$HOME/.ssh/config"<<EOF
Host github.com
  HostName github.com
  User git
  IdentityFile ${SSH_KEY_PATH}
  IdentitiesOnly yes
EOF
    chmod 600 "$HOME/.ssh/config"
  fi

  # Agent + add
  eval "$(ssh-agent -s)"
  ssh-add "$SSH_KEY_PATH"
}

ensure_gh_login() {
  if gh auth status >/dev/null 2>&1; then
    ok "GitHub CLI déjà authentifié."
    return
  fi
  if [[ -n "${GH_TOKEN:-}" ]]; then
    say "Authentification gh via GH_TOKEN (non interactif)"
    echo "$GH_TOKEN" | gh auth login --with-token
  else
    say "Ouverture d'une authentification gh interactive..."
    gh auth login
  fi
  gh auth status || err "Échec d'auth gh"
}

clone_repo_ssh() {
  local repo_ssh="git@github.com:${REPO_SLUG}.git"
  mkdir -p "$(dirname "$CLONE_DIR")"
  if [[ -d "$CLONE_DIR/.git" ]]; then
    warn "Le dépôt existe déjà: $CLONE_DIR"
  else
    say "Clone via SSH: $repo_ssh -> $CLONE_DIR"
    git clone "$repo_ssh" "$CLONE_DIR"
  fi
  ok "Terminé. Repo: $CLONE_DIR"
}

clone_repo_https() {
  local repo_https="https://github.com/${REPO_SLUG}.git"
  mkdir -p "$(dirname "$CLONE_DIR")"
  if [[ -d "$CLONE_DIR/.git" ]]; then
    warn "Le dépôt existe déjà: $CLONE_DIR"
  else
    say "Clone via HTTPS: $repo_https -> $CLONE_DIR"
    git clone "$repo_https" "$CLONE_DIR"
  fi
  ok "Terminé. Repo: $CLONE_DIR"
}

# =========================
#  Modes
# =========================
mode_ssh_account_key() {
  # 1) Clé SSH rattachée au COMPTE GitHub (accès global)
  ensure_ssh_config
  ensure_gh_login || true

  say "Ajout de la clé publique au COMPTE GitHub (SSH Keys du profil)"
  if gh auth status >/dev/null 2>&1; then
    local title="vps-$(hostname)-$(date +%F)"
    gh ssh-key add "${SSH_KEY_PATH}.pub" -t "$title" || warn "Impossible d'ajouter automatiquement la clé (droits?). Ajoute-la manuellement."
  else
    warn "gh non authentifié : ajoute manuellement la clé publique dans GitHub > Settings > SSH and GPG keys."
    echo "Clé publique: ${SSH_KEY_PATH}.pub"
  fi

  say "Test SSH → github.com"
  ssh -T git@github.com || true

  clone_repo_ssh
}

mode_ssh_deploy_key() {
  # 2) Clé SSH déposée en tant que DEPLOY KEY sur un REPO précis (accès restreint)
  ensure_ssh_config
  ensure_gh_login

  say "Ajout de la clé publique comme DEPLOY KEY sur ${REPO_SLUG}"
  local title="deploy-$(hostname)-$(date +%F)"
  # --allow-write pour autoriser push (sinon lecture seule)
  gh repo deploy-key add "${SSH_KEY_PATH}.pub" --repo "${REPO_SLUG}" -t "$title" --allow-write || \
    warn "Échec de l'ajout deploy-key. Vérifie que tu as les droits maintainer/admin sur ${REPO_SLUG}."

  say "Test SSH → github.com"
  ssh -T git@github.com || true

  clone_repo_ssh
}

mode_https_pat() {
  # 3) Connexion persistante via HTTPS + PAT (credential helper gh)
  ensure_gh_login
  say "Configuration du credential helper git via gh"
  gh auth setup-git

  clone_repo_https
}

# =========================
#  Menu
# =========================
menu() {
  cat <<'EOM'

Sélectionne le mode de connexion GitHub pour ce VPS:

  [1] SSH - Clé liée au COMPTE GitHub (accès global aux dépôts autorisés)
  [2] SSH - Deploy Key liée uniquement au dépôt (accès limité à ce repo)
  [3] HTTPS + PAT via GitHub CLI (connexion persistante sans ressaisie)

EOM
  read -rp "Ton choix [1/2/3]: " choice
  case "${choice:-1}" in
    1) mode_ssh_account_key ;;
    2) mode_ssh_deploy_key ;;
    3) mode_https_pat ;;
    *) warn "Choix invalide, on utilise [1] par défaut."; mode_ssh_account_key ;;
  esac
}

# =========================
#  MAIN
# =========================
say "Bootstrap GitHub sur VPS"
say "Repo ciblé : ${REPO_SLUG}"
say "Répertoire clone : ${CLONE_DIR}"

install_deps
menu

ok "Fini. Astuces :
 - git remote -v        # vérifier l’URL (ssh ou https)
 - gh auth status       # statut d'authentification GitHub CLI
 - ssh -T git@github.com  # test SSH"
