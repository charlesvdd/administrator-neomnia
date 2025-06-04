#!/usr/bin/env bash
set -euo pipefail

# ┌───────────────────────────────────────────────────────────────────────────┐
# │ (0) Vérifier qu'on est bien root, sinon on quitte en demandant sudo     │
# └───────────────────────────────────────────────────────────────────────────┘
if [[ $EUID -ne 0 ]]; then
  echo "‼️  Ce script doit impérativement être lancé en root."
  echo "   Relancez la commande comme ceci :"
  echo
  echo "     sudo curl -fsSL https://raw.githubusercontent.com/charlesvdd/administrator-neomnia/api-key-github/gitexe.sh | sudo bash"
  echo
  exit 1
fi
echo "→ OK, lancé en tant que root (UID=0)."

# ┌───────────────────────────────────────────────────────────────────────────┐
# │ (1) Création d’un dossier temporaire sous /tmp                          │
# └───────────────────────────────────────────────────────────────────────────┘
TMP_DIR="$(mktemp -d -t github-repo-XXXXXXXXXX)"
if [[ ! -d "$TMP_DIR" ]]; then
  echo "‼️  Impossible de créer un dossier temporaire dans /tmp."
  exit 1
fi
echo "→ (1) Dossier temporaire créé : $TMP_DIR"

# ┌───────────────────────────────────────────────────────────────────────────┐
# │ (2) Clonage du dépôt dans ce TMP_DIR                                      │
# └───────────────────────────────────────────────────────────────────────────┘
REPO_URL="https://github.com/charlesvdd/administrator-neomnia.git"
BRANCH="api-key-github"

echo "→ (2) Clonage du dépôt Git dans $TMP_DIR (branche '$BRANCH')…"
git clone --branch "$BRANCH" --depth 1 "$REPO_URL" "$TMP_DIR"
echo "→ Clone terminé."

# ┌───────────────────────────────────────────────────────────────────────────┐
# │ (3) Vérifier et exécuter gitkey-install                                   │
# └───────────────────────────────────────────────────────────────────────────┘
LOCAL_SCRIPT="$TMP_DIR/gitkey-install"
if [[ ! -f "$LOCAL_SCRIPT" ]]; then
  echo "‼️  Erreur : gitkey-install introuvable dans le dépôt."
  echo "    Assurez‐vous que ce fichier existe bien à la racine du repo."
  rm -rf "$TMP_DIR"
  exit 1
fi

chmod +x "$LOCAL_SCRIPT"
echo "→ (3) Exécution de gitkey-install (prompt credentials)…"
bash "$LOCAL_SCRIPT"

# ┌───────────────────────────────────────────────────────────────────────────┐
# │ (4) Nettoyage : suppression du dossier temporaire                         │
# └───────────────────────────────────────────────────────────────────────────┘
echo "→ (4) Suppression du clone temporaire : $TMP_DIR"
rm -rf "$TMP_DIR"
echo "→ Dossier temporaire supprimé."
echo "→ gitexe.sh a terminé toutes les étapes."
exit 0
