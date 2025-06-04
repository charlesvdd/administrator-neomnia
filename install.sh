#!/usr/bin/env bash
#
# install.sh – Validation GitHub + clonage du dépôt
#
# Usage :
#   sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/charlesvdd/administrator-neomnia/api-key-github/install.sh)"
#

set -euo pipefail

# 1. Vérifier qu’on est root
if [[ "$EUID" -ne 0 ]]; then
  echo "❌ Ce script doit être exécuté en root."
  echo "   Relancez-le avec : sudo $0"
  exit 1
fi

# 2. Boucle de saisie et validation des identifiants GitHub
#    On teste en appelant l’API /user. Si HTTP=200, on sort de la boucle.
function prompt_and_validate_github() {
  local http_code
  while true; do
    echo "===== [Étape 0] — Informations GitHub ====="
    read -p "Nom d’utilisateur GitHub : " GITHUB_USER
    read -s -p "Clé API GitHub (input masqué) : " GITHUB_API_KEY
    echo -e "\n"

    # Test simple : GET /user
    http_code=$(curl -s -o /dev/null -w "%{http_code}" \
      -H "Authorization: token ${GITHUB_API_KEY}" \
      https://api.github.com/user)

    if [[ "$http_code" -eq 200 ]]; then
      echo "✔ Authentification GitHub réussie pour '${GITHUB_USER}'."
      export GITHUB_USER GITHUB_API_KEY
      break
    else
      echo "⚠️ Authentification échouée (HTTP ${http_code})."
      echo "   Vérifiez votre login et votre clé API, puis réessayez."
      echo
    fi
  done
}

prompt_and_validate_github

# 3. Affichage d’un titre d’étape
function stage() {
  local num="$1"; shift
  local msg="$*"
  echo -e "\n===== [Étape $num] — $msg ====="
}

# 4. Clonage (ou mise à jour) du dépôt
stage 1 "Clonage / mise à jour du dépôt GitHub dans /opt/administrator-neomnia"

REPO="administrator-neomnia"
TARGET_DIR="/opt/${REPO}"

if [[ -d "$TARGET_DIR" ]]; then
  echo "→ Le dossier ${TARGET_DIR} existe déjà. On fait un git pull pour mettre à jour."
  git -C "$TARGET_DIR" pull
else
  echo "→ Clonage depuis GitHub : ${GITHUB_USER}/${REPO}"
  git clone "https://${GITHUB_USER}:${GITHUB_API_KEY}@github.com/${GITHUB_USER}/${REPO}.git" \
    "$TARGET_DIR"
fi

# 5. Fin du script
stage 2 "Terminé"
echo "Votre dépôt est désormais cloné dans '${TARGET_DIR}'."
echo "Si vous souhaitez ajouter d’autres étapes (copie de fichiers, lancement de setup.sh, etc.),"
echo "éditez ce fichier ou ajoutez un script 'setup.sh' à la racine de ${TARGET_DIR}."

echo -e "\n✅ Installation du dépôt GitHub terminée."
