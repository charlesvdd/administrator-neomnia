#!/usr/bin/env bash

# Script pour valider les informations GitHub et cloner un dépôt

set -euo pipefail

# Fonction pour encoder la clé API en base64
encode_github_key() {
  echo -n "$1" | base64
}

# Fonction pour décoder la clé API depuis base64
decode_github_key() {
  echo "$1" | base64 --decode
}

# Fonction pour demander et valider les informations GitHub
prompt_and_validate_github() {
  while true; do
    read -p "GitHub Username: " GITHUB_USER
    read -s -p "GitHub API Key (input hidden): " GITHUB_API_KEY
    echo

    # Encoder et stocker la clé GitHub
    encoded_key=$(encode_github_key "$GITHUB_API_KEY")
    echo "$encoded_key" > /path/to/secure/location/github_key.enc

    # Vérification de l'authentification
    http_code=$(curl -s -o /dev/null -w "%{http_code}" \
      -H "Authorization: token ${GITHUB_API_KEY}" \
      https://api.github.com/user)

    if [[ "$http_code" -ne 200 ]]; then
      echo "Authentication failed (HTTP ${http_code})."
      echo "Please check your API key and try again."
      continue
    fi

    api_login=$(curl -s \
      -H "Authorization: token ${GITHUB_API_KEY}" \
      https://api.github.com/user | grep -m1 '"login"' | cut -d '"' -f4)

    if [[ "$api_login" != "$GITHUB_USER" ]]; then
      echo "The token provided does not belong to user '${GITHUB_USER}', but to '${api_login}'. Please re-enter your credentials."
      continue
    fi

    echo "Authentication successful for user '${GITHUB_USER}'."
    export GITHUB_USER
    break
  done
}

# Exécuter la fonction pour obtenir et valider les informations GitHub
prompt_and_validate_github

# Décoder la clé GitHub API lorsque nécessaire
GITHUB_API_KEY=$(decode_github_key "$(cat /path/to/secure/location/github_key.enc)")

# Cloner ou mettre à jour le dépôt GitHub
REPO="administrator-neomnia"
TARGET_DIR="/opt/${REPO}"

if [[ -d "$TARGET_DIR" ]]; then
  echo "The directory ${TARGET_DIR} already exists. Running git pull to update..."
  git -C "$TARGET_DIR" pull && echo "Repository update completed successfully."
else
  echo "Cloning repository: ${GITHUB_USER}/${REPO}"
  git clone "https://${GITHUB_API_KEY}@github.com/${GITHUB_USER}/${REPO}.git" "$TARGET_DIR" && echo "Clone finished in '${TARGET_DIR}'."
fi

echo "Your repository is now ready in '${TARGET_DIR}'."
