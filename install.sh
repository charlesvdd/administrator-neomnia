#!/usr/bin/env bash
#===============================================================================
#
# install.sh — Installation locale de Git & GitHub CLI (sans prompt GitHub)
#
# Auteur   : Charles van den Driessche (version simplifiée)
# Licence  : GNU GPL v3
#
#===============================================================================

set -euo pipefail

print_header() {
  local title="$1"
  echo
  echo "───────────────────────────────────────────────────────────────────────────────"
  echo "   ${title}"
  echo "───────────────────────────────────────────────────────────────────────────────"
}

command_exists() {
  command -v "$1" &>/dev/null
}

#═══════════════════════ 1) Mise à jour du système ════════════════════════════

print_header "Mise à jour du système"
echo "  - Mise à jour des listes de paquets (apt-get update)…"
sudo apt-get update -y
echo "  - Mise à niveau des paquets installés (apt-get upgrade)…"
sudo apt-get upgrade -y
echo "✔ Système Linux mis à jour."

#═══════════════════════ 2) Installation de Git ════════════════════════════════

print_header "Installation de Git"
if ! command_exists git; then
  echo "  - Installation de Git…"
  sudo apt-get install -y git
else
  echo "  - Git est déjà installé (version : $(git --version))."
fi

#═══════════════════════ 3) Installation de GitHub CLI (gh) ═════════════════════

print_header "Installation de GitHub CLI"
if ! command_exists gh; then
  echo "  - Installation des prérequis (curl)…"
  sudo apt-get install -y curl

  echo "  - Import de la clé GPG officielle de GitHub CLI…"
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
       | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
  sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg

  echo "  - Ajout du dépôt GitHub CLI à /etc/apt/sources.list.d/gh-cli.list…"
  echo "deb [arch=$(dpkg --print-architecture) \
signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
https://cli.github.com/packages stable main" \
       | sudo tee /etc/apt/sources.list.d/gh-cli.list >/dev/null

  echo "  - Mise à jour apt…"
  sudo apt-get update -y
  echo "  - Installation de GitHub CLI (gh)…"
  sudo apt-get install -y gh
  echo "✔ GitHub CLI (gh) installé (version : $(gh --version | head -n1))."
else
  echo "  - GitHub CLI (gh) est déjà installé (version : $(gh --version | head -n1))."
fi

#═══════════════════════ 4) Configuration Git locale ════════════════════════════

print_header "Configuration Git locale"
CURRENT_NAME="$(git config --global user.name || echo "")"
CURRENT_EMAIL="$(git config --global user.email || echo "")"

if [[ -z "$CURRENT_NAME" ]]; then
  read -rp "➤ Entrez votre nom complet pour Git (par ex. “John Doe”) : " GIT_FULLNAME
  git config --global user.name "$GIT_FULLNAME"
  echo "→ Git user.name configuré à '$GIT_FULLNAME'."
else
  echo "→ Git user.name déjà défini : $CURRENT_NAME"
fi

if [[ -z "$CURRENT_EMAIL" ]]; then
  read -rp "➤ Entrez votre email pour Git (par ex. “email@exemple.com”) : " GIT_EMAIL
  git config --global user.email "$GIT_EMAIL"
  echo "→ Git user.email configuré à '$GIT_EMAIL'."
else
  echo "→ Git user.email déjà défini : $CURRENT_EMAIL"
fi

#═══════════════════════ 5) Génération de la clé SSH si nécessaire ══════════════

print_header "Configuration SSH"
if [[ ! -f "$HOME/.ssh/id_rsa.pub" ]]; then
  echo "  - Aucune clé SSH détectée. Génération d’une paire de clés SSH…"
  read -rp "   Entrez votre email pour la clé SSH (laisse vide pour utiliser l’email Git configuré) : " SSH_EMAIL
  if [[ -z "$SSH_EMAIL" ]]; then
    SSH_EMAIL="$GIT_EMAIL"
  fi
  ssh-keygen -t rsa -b 4096 -C "$SSH_EMAIL" -f "$HOME/.ssh/id_rsa" -N ""
  echo "✔ Paire de clés SSH générée."
else
  echo "  - Clé SSH existante détectée : ~/.ssh/id_rsa.pub"
fi

echo
echo "→ Clé publique SSH (~/.ssh/id_rsa.pub) :"
echo "---------------------------------------------------------"
cat "$HOME/.ssh/id_rsa.pub"
echo "---------------------------------------------------------"
echo "Ajoutez cette clé à GitHub : https://github.com/settings/keys"
echo

#═══════════════════════ 6) Message de fin ═════════════════════════════════════

print_header "Installation terminée"
echo "✔ Git, GitHub CLI et clé SSH configurés localement."
echo "✔ Pensez à exécuter manuellement :"
echo "     gh auth login"
echo "  pour authentifier 'gh' avec votre compte GitHub."
echo
echo "Vous pouvez désormais :"
echo "  • Cloner un dépôt SSH → git clone git@github.com:VOTRE_USER/NOM_DU_REPO.git"
echo "  • Vérifier le statut 'gh'   → gh auth status"
echo "  • Gérer vos dépôts via 'gh' → gh repo list VOTRE_USER"
echo
