#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Script : git-wrapper.sh
# Objectif :
#   1) Installer Git et GitHub CLI (gh) si absents.
#   2) Demander (ou lire depuis une variable ENV) le Personal Access Token (PAT).
#   3) Encoder le PAT en Base64 et le stocker dans ~/.github_token (chmod 600).
#   4) Authentifier la CLI GitHub (`gh auth login`) sous l’utilisateur non-root.
#   5) Configurer `gh config set user` sous l’utilisateur non-root.
#
# Usage :
#   1) Télécharger + exécuter (recommandé, inspecter d’abord) :
#        curl -sL https://raw.githubusercontent.com/charlesvdd/administrator-neomnia/api-key-github/git-wrapper.sh \
#          -o git-wrapper.sh
#        chmod +x git-wrapper.sh
#        ./git-wrapper.sh
#
#   2) En une seule commande (TTY requis pour la saisie interactive) :
#        curl -sL https://raw.githubusercontent.com/charlesvdd/administrator-neomnia/api-key-github/git-wrapper.sh | bash
#
# Remarques :
#   • Seuls les paquets système (git, gh) sont installés en root. Le reste se fait
#     sous l’utilisateur initial (SUDO_USER ou celui qui a lancé le script).
#   • Si la variable d’environnement GITHUB_TOKEN est définie, le script l’utilisera
#     sans demander de saisie interactive. Sinon, un TTY est requis pour `read -s`.
#   • Le fichier ~/.github_token est encodé en Base64 et protégé en mode 600.
# -----------------------------------------------------------------------------

set -euo pipefail

# URL brute vers ce script (pour relance en mode pipe)
readonly SCRIPT_URL="https://raw.githubusercontent.com/charlesvdd/administrator-neomnia/api-key-github/git-wrapper.sh"

# 0) Auto-élévation : si pas root, relancer en sudo pour installer les paquets
if [ "$EUID" -ne 0 ]; then
  echo "🔄 Relance du script en root..."
  base0=$(basename "$0")
  if [ -f "$0" ] && [[ "$base0" != "bash" && "$base0" != "sh" ]]; then
    exec sudo bash "$0" "$@"
  else
    exec sudo bash -c "curl -sL $SCRIPT_URL | bash"
  fi
fi

# À partir d'ici, on est root
ORIGINAL_USER="${SUDO_USER:-$(id -un)}"
USER_HOME=$(eval echo "~$ORIGINAL_USER")

# 1) Installer Git si nécessaire
if ! command -v git &> /dev/null; then
  echo "🔄 Git non trouvé. Installation en cours..."
  if command -v apt-get &> /dev/null; then
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y git
  elif command -v yum &> /dev/null; then
    yum install -y git
  else
    echo "❌ Aucun gestionnaire de paquets (apt-get ou yum) trouvé. Installez Git manuellement."
    exit 1
  fi
  echo "✅ Git installé."
else
  echo "✅ Git déjà présent."
fi

# 2) Installer GitHub CLI (gh) si nécessaire
if ! command -v gh &> /dev/null; then
  echo "🔄 GitHub CLI (gh) non trouvé. Installation en cours..."
  if command -v apt-get &> /dev/null; then
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y gh
  elif command -v yum &> /usr/bin/yum; then
    yum install -y https://github.com/cli/cli/releases/download/v2.46.0/gh_2.46.0_linux_amd64.rpm
  else
    echo "❌ Aucun gestionnaire de paquets (apt-get ou yum) trouvé. Installez GitHub CLI manuellement."
    exit 1
  fi
  echo "✅ GitHub CLI installé."
else
  echo "✅ GitHub CLI déjà présent."
fi

# 3) Lecture du Personal Access Token (PAT)
PAT=""
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  PAT="$GITHUB_TOKEN"
  echo "🔑 PAT chargé depuis la variable d’environnement."
else
  # Nécessite un TTY pour read -s
  if [[ ! -t 0 ]]; then
    echo "❌ Pas de terminal pour saisir le PAT. Définissez la variable \$GITHUB_TOKEN ou exécutez depuis un TTY."
    exit 1
  fi
  read -s -p "🔒 Personal Access Token GitHub : " PAT
  echo
fi

# 4) Encoder en Base64 et stocker dans ~/.github_token
ENCODED_TOKEN=$(printf "%s" "$PAT" | base64)
TOKEN_FILE="$USER_HOME/.github_token"

printf "%s" "$ENCODED_TOKEN" > "$TOKEN_FILE"
chown "$ORIGINAL_USER":"$ORIGINAL_USER" "$TOKEN_FILE"
chmod 600 "$TOKEN_FILE"
echo "✅ Token encodé en Base64 et enregistré dans : $TOKEN_FILE"

# 5) Authentifier gh sous l’utilisateur original
DECODED_TOKEN=$(base64 -d "$TOKEN_FILE")
sudo -u "$ORIGINAL_USER" bash -c "printf '%s' \"$DECODED_TOKEN\" | gh auth login --with-token"
echo "✅ Authentification GitHub CLI effectuée pour : $ORIGINAL_USER"

# 6) Configurer gh config set user
read -p "🔑 Nom d’utilisateur GitHub (pour gh config) : " GITHUB_USER
sudo -u "$ORIGINAL_USER" gh config set user "$GITHUB_USER" &> /dev/null || true
echo "✅ Configuration de l’utilisateur GitHub CLI : $GITHUB_USER"

echo
echo "🎉 Installation et configuration terminées."
echo "   • Git et gh sont installés."
echo "   • Token Base64 dans : $TOKEN_FILE"
echo "   • Authentifié sous : $GITHUB_USER"
