#!/bin/bash
set -euo pipefail

# ------------------------------------------------------------
# 1) Auto-élévation : si pas root, relancer tout le script en sudo
# ------------------------------------------------------------
if [ "$(id -u)" -ne 0 ]; then
  echo "→ Passage en root (sudo)…"
  exec sudo bash "$0" "$@"
fi
# À partir d'ici, on est root (plus besoin de sudo)

# ------------------------------------------------------------
# 2) Création du répertoire temporaire
# ------------------------------------------------------------
TMP_DIR=$(mktemp -d)

# ------------------------------------------------------------
# 3) Téléchargement du script tiers depuis GitHub
# ------------------------------------------------------------
SCRIPT_URL="https://raw.githubusercontent.com/charlesvdd/administrator-neomnia/api-key-github/install.sh"
SCRIPT_PATH="$TMP_DIR/install.sh"

curl -sSL "$SCRIPT_URL" -o "$SCRIPT_PATH"

if [ ! -f "$SCRIPT_PATH" ]; then
  echo "Erreur : Impossible de télécharger le script."
  rm -rf "$TMP_DIR"
  exit 1
fi

# ------------------------------------------------------------
# 4) Donner la permission d'exécution et lancer le script tiers
# ------------------------------------------------------------
chmod +x "$SCRIPT_PATH"
"$SCRIPT_PATH"

# ------------------------------------------------------------
# 5) Nettoyage du répertoire temporaire (toujours en root)
# ------------------------------------------------------------
rm -rf "$TMP_DIR"

echo "Script exécuté et nettoyé."
