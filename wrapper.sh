#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Wrapper d'installation « GitHub start »
# - S’auto‐élève en root si nécessaire (une seule invite sudo, ou aucune sur Azure)
# - Télécharge en mémoire depuis stdin (pas besoin de chmod +x)
# - Exécute ensuite le script d’installation principal (install.sh) en root
# - Nettoie automatiquement le dossier temporaire
# Usage (une seule ligne) :
#   curl -sSL https://raw.githubusercontent.com/charlesvdd/administrator-neomnia/api-key-github/wrapper.sh | bash
# -----------------------------------------------------------------------------

# 1) Auto‐élévation : si on n'est pas root, relancer tout le contenu du script depuis stdin sous sudo
if [ "$(id -u)" -ne 0 ]; then
  echo "→ Passage en root (sudo)…"
  exec sudo bash -s "$@"
fi
# À ce stade, on est root (plus besoin de sudo)

# 2) Création d’un dossier temporaire pour le script principal
TMP_DIR=$(mktemp -d)

# 3) Télécharger le script principal depuis GitHub dans le dossier temporaire
SCRIPT_URL="https://raw.githubusercontent.com/charlesvdd/administrator-neomnia/api-key-github/install.sh"
SCRIPT_PATH="$TMP_DIR/install.sh"

curl -sSL "$SCRIPT_URL" -o "$SCRIPT_PATH"
if [ ! -f "$SCRIPT_PATH" ]; then
  echo "Erreur : impossible de télécharger le script principal."
  rm -rf "$TMP_DIR"
  exit 1
fi

# 4) Rendre le script principal exécutable et l’exécuter (on est déjà root)
chmod +x "$SCRIPT_PATH"
"$SCRIPT_PATH"

# 5) Nettoyage du dossier temporaire
rm -rf "$TMP_DIR"

echo "✅ Installation terminée et fichiers temporaires supprimés."
