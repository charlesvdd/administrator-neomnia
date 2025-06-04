#!/usr/bin/env bash

set -euo pipefail

# Fonction pour encoder les informations
encode_github_credentials() {
  local username="$1"
  local api_key="$2"
  echo "$username:$api_key" | base64
}

# Fonction pour décoder les informations
decode_github_credentials() {
  local encoded_credentials="$1"
  echo "$encoded_credentials" | base64 --decode
}

# Exemple d'utilisation
prompt_and_validate_github() {
  local http_code api_login
  while true; do
    echo "===== [Étape 0] — Informations GitHub ====="
    read -p "Nom d’utilisateur GitHub : " GITHUB_USER
    read -s -p "Clé API GitHub (input masqué) : " GITHUB_API_KEY
    echo -e "\n"

    http_code=$(curl -s -o /dev/null -w "%{http_code}" \
      -H "Authorization: token ${GITHUB_API_KEY}" \
      https://api.github.com/user)

    if [[ "$http_code" -ne 200 ]]; then
      echo "⚠️ Authentification échouée (HTTP ${http_code})."
      echo "   Vérifiez votre clé API, puis réessayez."
      echo
      continue
    fi

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

    echo "✔ Authentification réussie pour l’utilisateur '${GITHUB_USER}'."
    export GITHUB_USER GITHUB_API_KEY

    # Encoder et stocker les informations
    encoded_credentials=$(encode_github_credentials "$GITHUB_USER" "$GITHUB_API_KEY")
    echo "$encoded_credentials" > /path/to/encoded_credentials.txt
    break
  done
}

# Exemple de décodage et utilisation des informations
# encoded_credentials=$(cat /path/to/encoded_credentials.txt)
# decoded_credentials=$(decode_github_credentials "$encoded_credentials")
# GITHUB_USER=$(echo "$decoded_credentials" | cut -d: -f1)
# GITHUB_API_KEY=$(echo "$decoded_credentials" | cut -d: -f2)

prompt_and_validate_github

stage() {
  local num="$1"; shift
  local msg="$*"
  echo -e "\n===== [Étape $num] — $msg ====="
}

stage 1 "Clonage / mise à jour du dépôt GitHub dans /opt/administrator-neomnia"

REPO="administrator-neomnia"
TARGET_DIR="/opt/${REPO}"

if [[ -d "$TARGET_DIR" ]]; then
  echo "→ Le dossier ${TARGET_DIR} existe déjà. On fait un git pull pour mettre à jour."
  git -C "$TARGET_DIR" pull
else
  echo "→ Clonage depuis GitHub : ${GITHUB_USER}/${REPO}"
  git clone "https://${GITHUB_USER}:${GITHUB_API_KEY}@github.com/${GITHUB_USER}/${REPO}.git" "$TARGET_DIR"
fi

stage 2 "Terminé"
echo "✅ Votre dépôt est désormais cloné dans '${TARGET_DIR}'."
