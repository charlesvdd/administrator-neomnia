#!/usr/bin/env bash
set -euo pipefail

# ┌───────────────────────────────────────────────────────────────────────────┐
# │ 0) Vérifier qu’on tourne en root, sinon relancer en sudo               │
# └───────────────────────────────────────────────────────────────────────────┘
if [[ $EUID -ne 0 ]]; then
  echo "→ Ce script doit être exécuté en root pour éviter les problèmes de permissions."
  echo "→ Relancement avec sudo..."
  exec sudo bash "$0" "$@"
fi
echo "→ Exécuté en tant que root (UID=0)."

# ┌───────────────────────────────────────────────────────────────────────────┐
# │ 1) Création d’un dossier temporaire dans /tmp                            │
# └───────────────────────────────────────────────────────────────────────────┘
TMP_DIR="$(mktemp -d -t github-repo-XXXXXXXXXX)"
if [[ ! -d "$TMP_DIR" ]]; then
  echo "‼️  Impossible de créer un dossier temporaire dans /tmp."
  exit 1
fi
echo "→ (1) Dossier temporaire créé : $TMP_DIR"

# ┌───────────────────────────────────────────────────────────────────────────┐
# │ 2) Cloner le dépôt dans ce TMP_DIR                                        │
# └───────────────────────────────────────────────────────────────────────────┘
REPO_URL="https://github.com/charlesvdd/administrator-neomnia.git"
BRANCH="api-key-github"

echo "→ (2) Clonage du dépôt Git dans $TMP_DIR (branche '$BRANCH')…"
git clone --branch "$BRANCH" --depth 1 "$REPO_URL" "$TMP_DIR"
echo "→ Clone terminé."

# ┌───────────────────────────────────────────────────────────────────────────┐
# │ 3) Vérifier que gitkey-install existe, le rendre exécutable, et l’exécuter │
# └───────────────────────────────────────────────────────────────────────────┘
LOCAL_SCRIPT="$TMP_DIR/gitkey-install"
if [[ ! -f "$LOCAL_SCRIPT" ]]; then
  echo "‼️  Erreur : gitkey-install introuvable dans le dépôt."
  echo "    Vérifiez que vous avez bien placé gitkey-install à la racine du repo."
  rm -rf "$TMP_DIR"
  exit 1
fi

chmod +x "$LOCAL_SCRIPT"
echo "→ (3) Lancement de gitkey-install (prompt credentials)…"
bash "$LOCAL_SCRIPT"

# ┌───────────────────────────────────────────────────────────────────────────┐
# │ 4) Nettoyer : suppression du dossier temporaire                           │
# └───────────────────────────────────────────────────────────────────────────┘
echo "→ (4) Nettoyage du clone temporaire : suppression de $TMP_DIR"
rm -rf "$TMP_DIR"
echo "→ Dossier temporaire supprimé."

echo "→ gitexe.sh a terminé toutes les étapes."
exit 0
