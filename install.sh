#!/usr/bin/env bash
#
# install.sh – Validation GitHub (login + token) + clonage du dépôt
#                + stockage chiffré du token
#
# Usage :
#   sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/charlesvdd/administrator-neomnia/api-key-github/install.sh)"
#

set -euo pipefail

# Répertoire et fichiers pour stocker en root (permissions strictes)
CREDENTIALS_DIR="/root/.administrator-neomnia"
USER_FILE="${CREDENTIALS_DIR}/user.txt"
TOKEN_FILE="${CREDENTIALS_DIR}/token.enc"

# 1. Vérifier qu’on est root
if [[ "$EUID" -ne 0 ]]; then
  echo "❌ Ce script doit être exécuté en root."
  echo "   Relancez-le avec : sudo $0"
  exit 1
fi

# 2. Fonction pour valider un couple (login, token) auprès de l’API GitHub
_validate_token() {
  local user="$1"
  local token="$2"
  local http_code api_login

  # 2.1. Test de validité du token via /user
  http_code=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: token ${token}" \
    https://api.github.com/user)

  if [[ "$http_code" -ne 200 ]]; then
    return 1
  fi

  # 2.2. Extraction du "login" réel depuis le JSON
  api_login=$(curl -s \
    -H "Authorization: token ${token}" \
    https://api.github.com/user \
    | grep -m1 '"login"' | cut -d '"' -f4)

  if [[ "$api_login" != "$user" ]]; then
    return 2
  fi

  return 0
}

# 3. Fonction pour demander login + token, valider, puis les stocker chiffrés
_prompt_and_store_github() {
  local http_code api_login PASS_PHRASE

  while true; do
    echo "===== [Étape 0] — Informations GitHub ====="
    read -p "Nom d’utilisateur GitHub : " GITHUB_USER
    read -s -p "Clé API GitHub (input masqué) : " GITHUB_API_KEY
    echo -e "\n"

    # Validation immédiate du token saisi
    _validate_token "$GITHUB_USER" "$GITHUB_API_KEY"
    case $? in
      1)
        echo "⚠️ Authentification échouée (token invalide ou expiré)."
        echo "   Vérifiez votre clé API, puis réessayez."
        echo
        continue
        ;;
      2)
        echo "⚠️ Le token fourni n’appartient pas à l’utilisateur '$GITHUB_USER'."
        echo "   Veuillez ressaisir les informations."
        echo
        continue
        ;;
      0)
        echo "✔ Authentification réussie pour l’utilisateur '${GITHUB_USER}'."

        # Création du répertoire sécurisé si nécessaire
        if [[ ! -d "$CREDENTIALS_DIR" ]]; then
          mkdir -p "$CREDENTIALS_DIR"
          chmod 700 "$CREDENTIALS_DIR"
        fi

        # Demander passphrase pour chiffrer le token
        read -s -p "Entrez une passphrase pour chiffrer le token GitHub : " PASS_PHRASE
        echo

        # Chiffrage du token
        echo -n "$GITHUB_API_KEY" | \
          openssl enc -aes-256-cbc -salt -pbkdf2 -pass pass:"$PASS_PHRASE" \
                      -out "$TOKEN_FILE"
        chmod 600 "$TOKEN_FILE"
        unset PASS_PHRASE

        # Stocker l’utilisateur en clair (permissions 600)
        echo "$GITHUB_USER" > "$USER_FILE"
        chmod 600 "$USER_FILE"

        export GITHUB_USER GITHUB_API_KEY
        break
        ;;
    esac
  done
}

# 4. Si on dispose déjà d’un TOKEN_FILE et USER_FILE, on tente de déchiffrer
if [[ -f "$TOKEN_FILE" && -f "$USER_FILE" ]]; then
  # Lecture de l’utilisateur
  GITHUB_USER=$(< "$USER_FILE")

  echo "→ Identifiants GitHub trouvés. Déchiffrement du token…"
  read -s -p "Entrez la passphrase pour déchiffrer le token GitHub : " PASS_PHRASE
  echo

  # Déchiffrement du token dans une variable
  GITHUB_API_KEY=$(openssl enc -d -aes-256-cbc -salt -pbkdf2 \
                    -pass pass:"$PASS_PHRASE" \
                    -in "$TOKEN_FILE") || {
    echo "🔴 Échec du déchiffrement (passphrase invalide ou fichier corrompu)."
    rm -f "$TOKEN_FILE" "$USER_FILE"
    echo "   Les fichiers chiffrés ont été supprimés. Relancez le script pour réinitialiser."
    exit 1
  }
  unset PASS_PHRASE

  # Vérification du token déchiffré
  _validate_token "$GITHUB_USER" "$GITHUB_API_KEY"
  case $? in
    0)
      echo "✔ Token valide pour '${GITHUB_USER}'."
      export GITHUB_USER GITHUB_API_KEY
      ;;
    *)
      echo "⚠️ Le token déchiffré n’est plus valide ou n’appartient pas à '${GITHUB_USER}'."
      rm -f "$TOKEN_FILE" "$USER_FILE"
      echo "   Les fichiers chiffrés ont été supprimés. Relancez le script pour réinitialiser."
      exit 1
      ;;
  esac

else
  # Pas de token stocké, on invite à saisir + valider + chiffrer
  _prompt_and_store_github
fi

# 5. Fonction utilitaire pour afficher un titre d’étape
stage() {
  local num="$1"; shift
  local msg="$*"
  echo -e "\n===== [Étape $num] — $msg ====="
}

# 6. Clonage (ou mise à jour) du dépôt
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

# 7. Fin du script
stage 2 "Terminé"
echo "✅ Votre dépôt est désormais cloné dans '${TARGET_DIR}'."
