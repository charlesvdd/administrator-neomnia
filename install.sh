#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# install-gh-server.sh
#
# Copyright (c) 2025 Charles van den Driessche - Neomnia
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the “Software”), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Script d’installation automatique de GitHub CLI (gh) avec :
#  • Bannières ASCII pour une « belle graphisème »
#  • Paramètre de serveur GitHub
#  • Authentification non-interactive via API key stockée dans GH_PAT
#
# Usage :
#   sudo bash <(curl -fsSL https://raw.githubusercontent.com/charlesvdd/kubesphere-install/main/install-gh-server.sh)
#
# Ce script :
# 1) Affiche une bannière ASCII « iconographique »
# 2) Demande à l’utilisateur de saisir le nom du serveur GitHub
# 3) Ajoute la clé GPG officielle de GitHub CLI
# 4) Ajoute le dépôt apt de GitHub CLI
# 5) Met à jour le cache apt
# 6) Installe le paquet gh (GitHub CLI) sans aucune invite
# 7) Configure automatiquement l’authentification gh en utilisant la clé API (GH_PAT)
# 8) Vérifie que gh est correctement configuré pour le serveur saisi
# -----------------------------------------------------------------------------
set -euo pipefail

# 0) Définition de la clé API (gh PAT) fournie
GH_PAT="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"

# 1) Affichage de la bannière ASCII « iconographique »
cat << 'EOF'

   ██████╗ ██╗   ██╗████████╗ ██████╗  ██████╗ 
  ██╔═══██╗██║   ██║╚══██╔══╝██╔═══██╗██╔═══██╗
  ██║   ██║██║   ██║   ██║   ██║   ██║██║   ██║
  ██║   ██║╚██╗ ██╔╝   ██║   ██║   ██║██║   ██║
  ╚██████╔╝ ╚████╔╝    ██║   ╚██████╔╝╚██████╔╝
   ╚═════╝   ╚═══╝     ╚═╝    ╚═════╝  ╚═════╝ 
                                            
   ██████╗ ██╗     ██╗██████╗ ███████╗██████╗ 
  ██╔════╝ ██║     ██║██╔══██╗██╔════╝██╔══██╗
  ██║  ███╗██║     ██║██████╔╝█████╗  ██████╔╝
  ██║   ██║██║     ██║██╔═══╝ ██╔══╝  ██╔══██╗
  ╚██████╔╝███████╗██║██║     ███████╗██║  ██║
   ╚═════╝ ╚══════╝╚═╝╚═╝     ╚══════╝╚═╝  ╚═╝
                                            
   Installation GitHub CLI (gh) - Neomnia 2025

EOF

echo ""

# 2) Demander le nom du serveur GitHub
read -p "Entrez le nom du serveur GitHub (ex. github.com ou votre-instance-enterprise) : " GITHUB_SERVER
GITHUB_SERVER=${GITHUB_SERVER:-github.com}
echo ""
echo "[INFO] Serveur GitHub sélectionné : $GITHUB_SERVER"
echo ""

# 3) Importation de la clé GPG officielle de GitHub CLI
echo "[INFO] Importation de la clé GPG de GitHub CLI…"
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
  | gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg

# 4) Ajout du dépôt GitHub CLI dans les sources apt
echo "[INFO] Ajout du dépôt GitHub CLI dans les sources apt…"
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
https://cli.github.com/packages stable main" \
  | tee /etc/apt/sources.list.d/github-cli.list > /dev/null

# 5) Mise à jour du cache apt
echo "[INFO] Mise à jour du cache apt…"
apt update -qq

# 6) Installation de gh
echo "[INFO] Installation de GitHub CLI (gh)…"
DEBIAN_FRONTEND=noninteractive apt install -y gh

# 7) Authentification non-interactive via la PAT pour le serveur spécifié
echo "[INFO] Configuration de l’authentification gh pour le serveur $GITHUB_SERVER …"
echo "$GH_PAT" | gh auth login --hostname "$GITHUB_SERVER" --with-token

# 8) Vérification de l’installation et de l’authentification
echo "[INFO] Vérification de l’installation de gh…"
if command -v gh >/dev/null 2>&1; then
  GH_VERSION=$(gh --version | head -n1)
  echo "[SUCCESS] GitHub CLI installé : $GH_VERSION"
else
  echo "[ERROR] L’installation de GitHub CLI a échoué." >&2
  exit 1
fi

echo "[INFO] Vérification de l’état d’authentification…"
if gh auth status --hostname "$GITHUB_SERVER" >/dev/null 2>&1; then
  echo "[SUCCESS] gh est connecté au serveur $GITHUB_SERVER"
else
  echo "[ERROR] L’authentification gh a échoué pour le serveur $GITHUB_SERVER" >&2
  exit 1
fi

echo ""
echo "[INFO] Installation et configuration de GitHub CLI terminées."
echo "Vous pouvez maintenant utiliser 'gh' pour interagir avec $GITHUB_SERVER."
echo ""
