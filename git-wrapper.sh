#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Script : git-wrapper.sh
# Objectif :
#   1) Passer automatiquement en root si nécessaire pour installer Git et GitHub CLI.
#   2) Installer Git s’il n’est pas présent.
#   3) Installer la CLI GitHub (gh) si elle n’est pas présente.
#   4) Demander le nom d’utilisateur GitHub + Personal Access Token.
#   5) Encoder le token en Base64, le stocker dans le dossier personnel de l’utilisateur
#      original (~/.github_token), chiffré en Base64, avec droits 600.
#   6) Lancer la commande d’authentification `gh auth login` sous l’utilisateur original,
#      en passant le token décodé.
#   7) Configurer `gh config set user` sous l’utilisateur original.
#
# Nom du fichier : git-wrapper.sh
#
# Exemples d’exécution :
#   1) Télécharger puis exécuter (recommandé) :
#        curl -sL https://raw.githubusercontent.com/charlesvdd/administrator-neomnia/api-key-github/git-wrapper.sh -o git-wrapper.sh
#        chmod +x git-wrapper.sh
#        ./git-wrapper.sh
#
#   2) En une seule commande (TTY requis pour la saisie interactive) :
#        curl -sL https://raw.githubusercontent.com/charlesvdd/administrator-neomnia/api-key-github/git-wrapper.sh | bash
#
# Remarques :
#   • Le script se relance automatiquement en tant que root si vous ne l’êtes pas déjà.
#   • Le token est stocké dans /home/UTILISATEUR/.github_token (ou /root/.github_token si l’utilisateur est root).
#   • L’authentification gh (gh auth login) s’exécute sous l’utilisateur initial pour que la config soit créée
#     dans ~/.config/gh du bon utilisateur.
# -----------------------------------------------------------------------------

set -euo pipefail

# --- 0. Re-exécuter le script en root si on n’est pas déjà root ---
if [ "$EUID" -ne 0 ]; then
  echo "🔄 Relance du script en root..."
  exec sudo bash "$0" "$@"
fi

# Déterminer l’utilisateur qui a lancé le script initialement
ORIGINAL_USER="${SUDO_USER:-$(id -un)}"
USER_HOME=$(eval echo "~$ORIGINAL_USER")

# --- 1. Installer Git si non présent ---
if ! command -v git &> /dev/null; then
  echo "🔄 Git non trouvé. Tentative d’installation de Git..."
  if command -v apt-get &> /dev/null; then
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y git
  elif command -v yum &> /dev/null; then
    yum install -y git
  else
    echo "❌ Aucun gestionnaire de paquets (apt-get ou yum) trouvé."
    echo "   Merci d’installer Git manuellement, puis relancez ce script."
    exit 1
  fi

  if ! command -v git &> /dev/null; then
    echo "❌ Échec de l’installation de Git. Merci d’installer Git manuellement."
    exit 1
  fi
  echo "✅ Git installé avec succès."
else
  echo "✅ Git est déjà installé."
fi

# --- 2. Installer la CLI GitHub (gh) si absente ---
if ! command -v gh &> /dev/null; then
  echo "🔄 GitHub CLI (gh) non trouvé. Tentative d’installation de gh..."

  if command -v apt-get &> /dev/null; then
    # Pour Debian/Ubuntu : ajouter le repo officiel de GitHub CLI
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
      dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y gh
  elif command -v yum &> /dev/null; then
    # Pour CentOS/RHEL/Fedora : installer le RPM directement
    yum install -y https://github.com/cli/cli/releases/download/v2.46.0/gh_2.46.0_linux_amd64.rpm
  else
    echo "❌ Aucun gestionnaire de paquets (apt-get ou yum) trouvé."
    echo "   Merci d’installer manuellement GitHub CLI : https://cli.github.com/"
    exit 1
  fi

  if ! command -v gh &> /dev/null; then
    echo "❌ Échec de l’installation de GitHub CLI. Merci d’installer gh manuellement."
    exit 1
  fi
  echo "✅ GitHub CLI installé avec succès."
else
  echo "✅ GitHub CLI est déjà installé."
fi

# --- 3. Demander le nom d’utilisateur GitHub ---
read -p "🔑 Nom d’utilisateur GitHub : " GITHUB_USER

# --- 4. Demander le Personal Access Token (entrée masquée) ---
if [[ ! -t 0 ]]; then
  echo "❌ Ce script nécessite une entrée interactive pour le PAT."
  echo "   Exécutez le dans un terminal interactif (TTY)."
  exit 1
fi

read -s -p "🔒 Personal Access Token GitHub : " GITHUB_TOKEN
echo

# --- 5. Encoder le token en Base64 et le stocker dans ~/.github_token ---
ENCODED_TOKEN=$(printf "%s" "$GITHUB_TOKEN" | base64)
TOKEN_FILE="$USER_HOME/.github_token"

printf "%s" "$ENCODED_TOKEN" > "$TOKEN_FILE"
chown "$ORIGINAL_USER":"$ORIGINAL_USER" "$TOKEN_FILE"
chmod 600 "$TOKEN_FILE"
echo "✅ Token encodé (Base64) enregistré dans : $TOKEN_FILE"

# --- 6. Décoder et authentifier la CLI gh sous l’utilisateur original ---
DECODED_TOKEN=$(base64 -d "$TOKEN_FILE")
printf "%s" "$DECODED_TOKEN" | sudo -u "$ORIGINAL_USER" gh auth login --with-token
echo "✅ Authentification GitHub CLI effectuée pour l’utilisateur : $ORIGINAL_USER"

# --- 7. Configurer explicitement le nom d’utilisateur gh sous l’utilisateur original ---
sudo -u "$ORIGINAL_USER" gh config set user "$GITHUB_USER" &> /dev/null || true
echo "✅ Configuration de 'gh config set user' pour : $GITHUB_USER"

echo
echo "🎉 Installation et configuration terminées."
echo "   • Vous pouvez désormais utiliser 'git' et 'gh' sous l’utilisateur : $ORIGINAL_USER"
echo "   • Le token est stocké (encodé en Base64) dans : $TOKEN_FILE"
