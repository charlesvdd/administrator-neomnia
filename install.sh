#!/usr/bin/env bash
#
# install.sh – Clonage du dépôt en stockant login+token dans /root/.netrc
#
# Usage :
#   sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/charlesvdd/administrator-neomnia/api-key-github/install.sh)"
#
# Ce script :
#   1. Vérifie si /root/.netrc existe et est fonctionnel.
#   2. S’il n’existe pas, demande login+token, le crée et le protège (chmod 600).
#   3. Valide le couple login/token en appelant l’API GitHub.
#   4. Clone (ou met à jour) le dépôt dans /opt/administrator-neomnia.
#

set -euo pipefail

# 1. Vérifier qu’on est root (nécessaire pour écrire /root/.netrc + cloner dans /opt)
if [[ "$EUID" -ne 0 ]]; then
  echo "❌ Ce script doit être exécuté en root."
  echo "   Relancez-le avec : sudo $0"
  exit 1
fi

NETRC_PATH="/root/.netrc"

# 2. Si /root/.netrc n’existe pas, on demande login+token et on l’écrit.
if [[ ! -r "$NETRC_PATH" ]]; then
  echo "===== [Étape 0] — Configuration de /root/.netrc ====="
  read -p "Nom d’utilisateur GitHub : " GITHUB_USER
  read -s -p "Clé API GitHub (token) : " GITHUB_API_KEY
  echo -e "\n"

  # Création de /root/.netrc
  cat > "$NETRC_PATH" <<EOF
machine github.com
  login $GITHUB_USER
  password $GITHUB_API_KEY
EOF
  chmod 600 "$NETRC_PATH"
  echo "✔ /root/.netrc créé et protégé (chmod 600)."
else
  # Si déjà présent, on peut lire le login pour l’afficher
  GITHUB_USER=$(grep -m1 '^  login ' "$NETRC_PATH" | cut -d ' ' -f3)
  echo "ℹ️ /root/.netrc trouvé (login : $GITHUB_USER)."
fi

# 3. Vérifier que le token stocké dans /root/.netrc est valide
echo "===== [Étape 1] — Validation du token GitHub ====="
http_code=$(curl -s -n -o /dev/null -w "%{http_code}" https://api.github.com/user)
if [[ "$http_code" -ne 200 ]]; then
  echo "❌ Le login ou le token dans /root/.netrc est invalide (HTTP $http_code)."
  echo "   Supprimez /root/.netrc et relancez le script pour ressaisir."
  exit 1
fi

# Récupérer le login réel pour vérification
current_login=$(curl -s -n https://api.github.com/user | grep -m1 '"login"' | cut -d '"' -f4)
if [[ "$current_login" != "$GITHUB_USER" ]]; then
  echo "❌ Le token appartient à '$current_login', mais /root/.netrc indique login='$GITHUB_USER'."
  echo "   Supprimez /root/.netrc et relancez le script pour corriger."
  exit 1
fi
echo "✔ Authentification GitHub réussie pour : $current_login"

# 4. Fonction utilitaire pour afficher les étapes
stage() {
  local num="$1"; shift
  local msg="$*"
  echo -e "\n===== [Étape $num] — $msg ====="
}

# 5. Clonage ou mise à jour du dépôt dans /opt/administrator-neomnia
stage 2 "Clonage / mise à jour du dépôt GitHub dans /opt/administrator-neomnia"
REPO="administrator-neomnia"
TARGET_DIR="/opt/${REPO}"

if [[ -d "$TARGET_DIR" ]]; then
  echo "→ Le dossier ${TARGET_DIR} existe déjà. Mise à jour (git pull)…"
  git -C "$TARGET_DIR" pull
else
  echo "→ Clonage du dépôt https://github.com/${current_login}/${REPO}.git"
  git clone "https://github.com/${current_login}/${REPO}.git" "$TARGET_DIR"
fi

# 6. Fin du script
stage 3 "Terminé"
echo "✅ Votre dépôt est cloné/mis à jour dans : ${TARGET_DIR}"
echo "   La prochaine fois, /root/.netrc sera lu automatiquement, plus besoin de ressaisir."
