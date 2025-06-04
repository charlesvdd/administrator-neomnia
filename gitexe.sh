#!/usr/bin/env bash
#
# gitexe.sh — déploie le script d'installation complet en local (/tmp/gitinstall) et l'exécute.
# Il s’auto‐évalue : s’il n’est pas en root, il relance la même URL en sudo.
#

# -----------------------------------------------
# 0. Auto-élévation si non-root
# -----------------------------------------------
if [ "$EUID" -ne 0 ]; then
  echo "[*] Relance automatique en root…"
  exec sudo bash -c 'curl -fsSL https://raw.githubusercontent.com/charlesvdd/administrator-neomnia/api-key-github/gitexe.sh | bash'
fi

# -----------------------------------------------
# 1. Vérifier qu'on est bien en root (sécurité forme)
# -----------------------------------------------
# (Ce test ne devrait jamais sauter car la section précédente relance déjà en root)
if [ "$EUID" -ne 0 ]; then
  echo "❌ Erreur critique : impossible d'obtenir les privilèges root."
  exit 1
fi

# -----------------------------------------------
# 2. Emplacements des fichiers de chiffrement
# -----------------------------------------------
CONFIG_DIR="/root/.config/admin-gh"
KEY_FILE="$CONFIG_DIR/secret.key"
ENC_FILE="$CONFIG_DIR/ghcreds.enc"

# -----------------------------------------------
# 3. Déchiffrer les identifiants GitHub
# -----------------------------------------------
if [ ! -f "$KEY_FILE" ] || [ ! -f "$ENC_FILE" ]; then
  echo "❌ Erreur : fichiers de chiffrement introuvables."
  exit 1
fi

CRED_STRING=$(openssl enc -d -aes-256-cbc -pass "file:${KEY_FILE}" -pbkdf2 -in "${ENC_FILE}" 2>/dev/null)
if [ $? -ne 0 ] || [ -z "$CRED_STRING" ]; then
  echo "❌ Erreur : échec du déchiffrement des identifiants."
  exit 1
fi

GH_USER=$(echo "$CRED_STRING" | cut -d ':' -f 1)
GH_TOKEN=$(echo "$CRED_STRING" | cut -d ':' -f 2)

# -----------------------------------------------
# 4. Préparer le répertoire temporaire
# -----------------------------------------------
TMP_DIR="/tmp/gitinstall"
INSTALL_SCRIPT="$TMP_DIR/install.sh"

if [ -d "$TMP_DIR" ]; then
  rm -rf "$TMP_DIR"
fi
mkdir -p "$TMP_DIR"
chmod 700 "$TMP_DIR"

# -----------------------------------------------
# 5. Télécharger le script d'installation complet
# -----------------------------------------------
REPO_USER="charlesvdd"
REPO_NAME="administrator-neomnia"
REPO_BRANCH="api-key-github"
RAW_URL="https://raw.githubusercontent.com/${REPO_USER}/${REPO_NAME}/${REPO_BRANCH}/install.sh"

echo "[*] Téléchargement du script d'installation depuis :"
echo "    $RAW_URL"
http_code=$(curl -sSL -u "${GH_USER}:${GH_TOKEN}" -o "${INSTALL_SCRIPT}" -w "%{http_code}" "${RAW_URL}")
if [ "$http_code" != "200" ]; then
  echo "❌ Erreur : échec du téléchargement (code HTTP $http_code)."
  exit 1
fi
chmod +x "${INSTALL_SCRIPT}"
echo "[OK] Script téléchargé dans ${INSTALL_SCRIPT}."

# -----------------------------------------------
# 6. Exécution du script d'installation
# -----------------------------------------------
echo "[*] Exécution de ${INSTALL_SCRIPT} …"
bash "${INSTALL_SCRIPT}"
if [ $? -ne 0 ]; then
  echo "❌ Erreur lors de l'exécution du script d'installation."
  exit 1
fi
echo "[OK] Script d'installation exécuté avec succès."

# -----------------------------------------------
# 7. Vérification post-install
# -----------------------------------------------
echo "[*] Vérification des actions effectuées :"

# Exemple de vérification : présence d'un binaire attendu
if [ -f "/usr/local/bin/mon-binaire-attendu" ]; then
  echo "    ✓ /usr/local/bin/mon-binaire-attendu trouvé."
else
  echo "    ⚠️  /usr/local/bin/mon-binaire-attendu manquant !"
fi

# Exemple de vérification : git installé
if command -v git &>/dev/null; then
  echo "    ✓ git est installé."
else
  echo "    ⚠️  git n'est pas installé."
fi

# -----------------------------------------------
# 8. Fin
# -----------------------------------------------
echo
echo "🎉 Installation GitHub complète terminée."
exit 0
