#!/usr/bin/env bash
#
# gitexe.sh — déploie le script d'installation complet (/tmp/gitinstall) et l'exécute.
# Il fait uniquement :
#  1) vérification root
#  2) déchiffrement des identifiants chiffrés générés par wrapper.sh
#  3) téléchargement/exécution de install.sh
#

# -----------------------------------------------
# 1. Vérifier qu'on est bien en root
# -----------------------------------------------
if [ "$(id -u)" -ne 0 ]; then
  echo "❌ Erreur : ce script doit être exécuté en root."
  echo "   Merci de le lancer avec : sudo gitstart  (ou sudo bash gitexe.sh)"
  exit 1
fi

# -----------------------------------------------
# 2. Emplacements attendus des fichiers de chiffrement
# -----------------------------------------------
CONFIG_DIR="/root/.config/admin-gh"
KEY_FILE="$CONFIG_DIR/secret.key"
ENC_FILE="$CONFIG_DIR/ghcreds.enc"

# -----------------------------------------------
# 3. Vérifier l'existence des fichiers chiffrés
# -----------------------------------------------
if [ ! -f "$KEY_FILE" ] || [ ! -f "$ENC_FILE" ]; then
  echo "❌ Erreur : identifiants GitHub chiffrés introuvables."
  echo "   Veuillez d'abord exécuter wrapper.sh pour saisir/chiffrer vos identifiants."
  echo "   Ex : sudo bash /usr/local/bin/wrapper.sh"
  exit 1
fi

# -----------------------------------------------
# 4. Déchiffrage des identifiants GitHub
# -----------------------------------------------
CRED_STRING=$(openssl enc -d -aes-256-cbc -pass "file:${KEY_FILE}" -pbkdf2 -in "${ENC_FILE}" 2>/dev/null)
if [ $? -ne 0 ] || [ -z "$CRED_STRING" ]; then
  echo "❌ Erreur : échec du déchiffrement des identifiants."
  exit 1
fi

GH_USER=$(echo "$CRED_STRING" | cut -d ':' -f 1)
GH_TOKEN=$(echo "$CRED_STRING" | cut -d ':' -f 2)

# -----------------------------------------------
# 5. Préparer le répertoire temporaire
# -----------------------------------------------
TMP_DIR="/tmp/gitinstall"
INSTALL_SCRIPT="$TMP_DIR/install.sh"

if [ -d "$TMP_DIR" ]; then
  rm -rf "$TMP_DIR"
fi
mkdir -p "$TMP_DIR"
chmod 700 "$TMP_DIR"

# -----------------------------------------------
# 6. Télécharger le script d’installation complet
# -----------------------------------------------
REPO_USER="charlesvdd"
REPO_NAME="administrator-neomnia"
REPO_BRANCH="api-key-github"
RAW_URL="https://raw.githubusercontent.com/${REPO_USER}/${REPO_NAME}/${REPO_BRANCH}/install.sh"

echo "[*] Téléchargement du script d’installation depuis :"
echo "    $RAW_URL"
http_code=$(curl -sSL -u "${GH_USER}:${GH_TOKEN}" -o "${INSTALL_SCRIPT}" -w "%{http_code}" "${RAW_URL}")
if [ "$http_code" != "200" ]; then
  echo "❌ Erreur : échec du téléchargement (code HTTP $http_code)."
  exit 1
fi

chmod +x "${INSTALL_SCRIPT}"
echo "[OK] Script téléchargé dans ${INSTALL_SCRIPT}."

# -----------------------------------------------
# 7. Exécution du script d’installation
# -----------------------------------------------
echo "[*] Exécution de ${INSTALL_SCRIPT}…"
bash "${INSTALL_SCRIPT}"
if [ $? -ne 0 ]; then
  echo "❌ Erreur lors de l'exécution du script d'installation."
  exit 1
fi
echo "[OK] Script d'installation exécuté avec succès."

# -----------------------------------------------
# 8. Vérification post-install (exemples)
# -----------------------------------------------
echo "[*] Vérification des actions effectuées :"

# Exemple : présence d’un binaire attendu
if [ -f "/usr/local/bin/mon-binaire-attendu" ]; then
  echo "    ✓ /usr/local/bin/mon-binaire-attendu trouvé."
else
  echo "    ⚠️  /usr/local/bin/mon-binaire-attendu manquant !"
fi

# Exemple : git installé
if command -v git &>/dev/null; then
  echo "    ✓ git est installé."
else
  echo "    ⚠️  git n'est pas installé."
fi

# -----------------------------------------------
# 9. Fin
# -----------------------------------------------
echo
echo "🎉 Installation GitHub complète terminée."
exit 0
