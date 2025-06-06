#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Script : wrapper.sh
# Objectif : Installer Git, configurer et installer la CLI GitHub (si besoin),
#            demander nom d’utilisateur et Personal Access Token (PAT), stocker
#            ce token encodé en Base64, puis s’authentifier automatiquement à la CLI.
#
# Usage (exécuté depuis GitHub raw ou local) :
#   1) Télécharger puis exécuter (recommandé) :
#        curl -sL https://raw.githubusercontent.com/charlesvdd/administrator-neomnia/api-key-github/wrapper.sh -o wrapper.sh
#        chmod +x wrapper.sh
#        ./wrapper.sh
#
#   2) En une seule commande (TTY requis pour la saisie interactive) :
#        curl -sL https://raw.githubusercontent.com/charlesvdd/administrator-neomnia/api-key-github/wrapper.sh | bash
#
# Remarques :
#   - Ce script détecte et installe Git si nécessaire (via apt-get ou yum).
#   - S’il manque la CLI GitHub (gh), il propose son installation automatique.
#   - Le Personal Access Token sera encodé en Base64 et stocké dans ~/.github_token (chmod 600).
#   - À chaque exécution, le token existant est écrasé par la nouvelle saisie interactive.
# -----------------------------------------------------------------------------

set -euo pipefail

# --- 1. Installer Git si non présent ---
if ! command -v git &> /dev/null; then
  echo "🔄 Git non trouvé. Tentative d'installation de Git..."
  if command -v apt-get &> /dev/null; then
    sudo apt-get update
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y git
  elif command -v yum &> /dev/null; then
    sudo yum install -y git
  else
    echo "Erreur : aucun gestionnaire de paquets compatible (apt-get ou yum) n'a été trouvé."
    echo "Merci d'installer Git manuellement, puis relancez ce script."
    exit 1
  fi

  # Vérifier à nouveau
  if ! command -v git &> /dev/null; then
    echo "Échec de l'installation de Git. Veuillez installer Git manuellement."
    exit 1
  fi

  echo "✅ Git installé avec succès."
else
  echo "✅ Git est déjà installé."
fi

# --- 2. Vérifier / installer la CLI GitHub (gh) si absente ---
if ! command -v gh &> /dev/null; then
  echo "🔄 GitHub CLI (gh) non trouvé. Tentative d'installation de gh..."

  if command -v apt-get &> /dev/null; then
    # Pour Debian/Ubuntu, ajouter le repo officiel de GitHub CLI
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
      sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
https://cli.github.com/packages stable main" | \
      sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt-get update
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y gh
  elif command -v yum &> /dev/null; then
    # Pour CentOS/RHEL/Fedora
    sudo yum install -y https://github.com/cli/cli/releases/download/v2.46.0/gh_2.46.0_linux_amd64.rpm
  else
    echo "Erreur : aucun gestionnaire de paquets compatible (apt-get ou yum) n'a été trouvé."
    echo "Merci d'installer manuellement GitHub CLI : https://cli.github.com/"
    exit 1
  fi

  # Vérifier à nouveau
  if ! command -v gh &> /dev/null; then
    echo "Échec de l'installation de GitHub CLI. Veuillez installer gh manuellement."
    exit 1
  fi

  echo "✅ GitHub CLI installé avec succès."
else
  echo "✅ GitHub CLI est déjà installé."
fi

# --- 3. Demander le nom d’utilisateur GitHub ---
read -p "🔑 Nom d’utilisateur GitHub : " GITHUB_USER

# --- 4. Demander le Personal Access Token (entrée masquée) ---
# On vérifie qu'on est dans un TTY pour que read -s fonctionne.
if [[ ! -t 0 ]]; then
  echo "Erreur : ce script nécessite une entrée interactive pour le PAT."
  echo "Veuillez exécuter ce script dans un terminal interactif."
  exit 1
fi

read -s -p "🔒 Personal Access Token GitHub : " GITHUB_TOKEN
echo

# --- 5. Encoder le token en Base64 et le stocker dans ~/.github_token ---
ENCODED_TOKEN=$(printf "%s" "$GITHUB_TOKEN" | base64)
TOKEN_FILE="$HOME/.github_token"

printf "%s" "$ENCODED_TOKEN" > "$TOKEN_FILE"
chmod 600 "$TOKEN_FILE"
echo "✅ Token encodé et enregistré (Base64) dans : $TOKEN_FILE"

# --- 6. Décoder instantanément pour authentifier la CLI GitHub ---
DECODED_TOKEN=$(base64 -d "$TOKEN_FILE")
printf "%s" "$DECODED_TOKEN" | gh auth login --with-token
echo "✅ Authentification GitHub CLI effectuée avec succès."

# --- 7. Configurer explicitement le nom d’utilisateur dans gh ---
gh config set user "$GITHUB_USER" &> /dev/null || true
echo "✅ Configuration GitHub CLI pour l’utilisateur : $GITHUB_USER"

echo
echo "🎉 La configuration est terminée."
echo "   Vous pouvez désormais utiliser 'git' et 'gh' normalement."
