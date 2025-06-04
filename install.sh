#!/usr/bin/env bash
#
# install.sh – Validation GitHub (login + token) + clonage du dépôt
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

# 2. Boucle de saisie et validation du couple (login, token)
#    On appelle /user, on extrait "login" du JSON, puis on compare.
prompt_and_validate_github() {
  local http_code api_login
  while true; do
    echo "===== [Étape 0] — Informations GitHub ====="
    read -p "Nom d’utilisateur GitHub : " GITHUB_USER
    read -s -p "Clé API GitHub (input masqué) : " GITHUB_API_KEY
    echo -e "\n"

    # 2.1. On interroge /user pour vérifier le token et récupérer le login associé
    #     - http_code permet de tester la validité du token
    #     - api_login est extrait du JSON pour vérifier le login
    http_code=$(curl -s -o /dev/null -w "%{http_code}" \
      -H "Authorization: token ${GITHUB_API_KEY}" \
      https://api.github.com/user)

    if [[ "$http_code" -ne 200 ]]; then
      echo "⚠️ Authentification échouée (HTTP ${http_code})."
      echo "   Vérifiez votre clé API, puis réessayez."
      echo
      continue
    fi

    # 2.2. Le token est valide (HTTP 200). On récupère le "login" réel depuis le JSON.
    api_login=$(curl -s \
      -H "Authorization: token ${GITHUB_API_KEY}" \
      https://api.github.com/user \
      | grep -m1 '"login"' | cut -d '"' -f4)

    if [[ "$api_login" != "$GITHUB_USER" ]]; then
      echo "⚠️ Le token fourni n’appartient pas à l’utilisateur '$GITHUB_USER',"
      echo "   mais à '$api_login'. Veuillez ressaisir les informations."
      echo
      continue
    fi

    # Si on arrive ici, token valide ET login concorde.
    echo "✔ Authentification réussie pour l’utilisateur '${GITHUB_USER}'."
    export GITHUB_USER GITHUB_API_KEY
    break
  done
}

prompt_and_validate_github

# 3. Fonction utilitaire pour afficher un titre d’étape
stage() {
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
echo "✅ Votre dépôt est désormais cloné dans '${TARGET_DIR}'."
