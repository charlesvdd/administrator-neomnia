#!/usr/bin/env bash
#
# install.sh – Clonage du dépôt sans resaisie du token (grâce à /root/.netrc)
#
# Usage :
#   1. As root, créez /root/.netrc comme expliqué (chmod 600).
#   2. Exécutez :
#        sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/charlesvdd/administrator-neomnia/api-key-github/install.sh)"
#

set -euo pipefail

# 1. Vérifier qu’on est root
if [[ "$EUID" -ne 0 ]]; then
  echo "❌ Ce script doit être exécuté en root."
  echo "   Relancez-le avec : sudo $0"
  exit 1
fi

# 2. Vérifier que /root/.netrc existe et contient des infos GitHub
if [[ ! -r "/root/.netrc" ]]; then
  echo "❌ Impossible de lire /root/.netrc."
  echo "   Créez-le en y plaçant :"
  echo "     machine github.com"
  echo "       login VOTRE_LOGIN"
  echo "       password VOTRE_TOKEN"
  echo "   Puis refaites : sudo bash -c \"\$(curl -fsSL https://...)
  exit 1
fi

# 3. Vérifier que le couple (login/token) dans .netrc est valide 
#    On interroge /user pour s’assurer qu’on obtient bien HTTP 200.
http_code=$(curl -s -n -o /dev/null -w "%{http_code}" https://api.github.com/user)
if [[ "$http_code" -ne 200 ]]; then
  echo "❌ Le login ou le token inscrit dans /root/.netrc semble invalide."
  echo "   (curl -n https://api.github.com/user renvoie HTTP $http_code)"
  echo "   Vérifiez /root/.netrc, corrigez le login/token, puis relancez ce script."
  exit 1
fi

# Facultatif : afficher le login effectif pour confirmation
current_login=$(curl -s -n https://api.github.com/user | grep -m1 '"login"' | cut -d '"' -f4)
echo "✔ Authentification GitHub réussie pour : $current_login"

# 4. Fonction utilitaire pour afficher les étapes
function stage() {
  local num="$1"; shift
  local msg="$*"
  echo -e "\n===== [Étape $num] — $msg ====="
}

# 5. Clonage ou mise à jour du dépôt dans /opt
stage 1 "Clonage / mise à jour du dépôt dans /opt/administrator-neomnia"
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
stage 2 "Terminé"
echo "✅ Votre dépôt est cloné/mis à jour dans : ${TARGET_DIR}"
echo "   Plus besoin de ressaisir le token, tout est lu dans /root/.netrc."
