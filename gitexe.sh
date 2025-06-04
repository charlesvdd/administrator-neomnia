#!/usr/bin/env bash
set -euo pipefail

# ┌───────────────────────────────────────────────────────────────────────────┐
# │ 1) Variables                                                            │
# └───────────────────────────────────────────────────────────────────────────┘
# Dossier TEMPORAIRE pour cloner le dépôt (dans /tmp pour éviter les problèmes de permission)
TMP_DIR="/tmp/github-repo-temp"

REPO_URL="https://github.com/charlesvdd/administrator-neomnia.git"
BRANCH="api-key-github"

# Là où on veut installer (copier) le script "gitkey-install"
DEST_DIR="/usr/local/bin"
LOCAL_SCRIPT_NAME="gitkey-install"

# ┌───────────────────────────────────────────────────────────────────────────┐
# │ 2) Nettoyage de TMP_DIR s’il existe déjà                                 │
# └───────────────────────────────────────────────────────────────────────────┘
if [ -d "$TMP_DIR" ]; then
  echo "→ Suppression de l’ancien dossier temporaire $TMP_DIR"
  rm -rf "$TMP_DIR"
fi

# ┌───────────────────────────────────────────────────────────────────────────┐
# │ 3) Clonage du dépôt GitHub dans TMP_DIR                                   │
# └───────────────────────────────────────────────────────────────────────────┘
echo "→ Clonage du dépôt Git dans $TMP_DIR (branche '$BRANCH')…"
git clone --branch "$BRANCH" "$REPO_URL" "$TMP_DIR"
echo "→ Clone terminé."

# ┌───────────────────────────────────────────────────────────────────────────┐
# │ 4) Vérifier l’existence de gitkey-install et le copier                     │
# └───────────────────────────────────────────────────────────────────────────┘
if [ ! -f "$TMP_DIR/$LOCAL_SCRIPT_NAME" ]; then
  echo "‼️  Erreur : le fichier $LOCAL_SCRIPT_NAME n’existe pas dans le dépôt."
  echo "    Vérifiez que votre dépôt contient bien ce fichier à la racine."
  rm -rf "$TMP_DIR"
  exit 1
fi

# Copier gitkey-install dans /usr/local/bin (avec sudo)
echo "→ Copie de $LOCAL_SCRIPT_NAME vers $DEST_DIR/$LOCAL_SCRIPT_NAME…"
sudo mkdir -p "$DEST_DIR"
sudo cp "$TMP_DIR/$LOCAL_SCRIPT_NAME" "$DEST_DIR/$LOCAL_SCRIPT_NAME"
sudo chmod +x "$DEST_DIR/$LOCAL_SCRIPT_NAME"
echo "→ Copie et chmod +x réussis."

# ┌───────────────────────────────────────────────────────────────────────────┐
# │ 5) Suppression du clone temporaire                                         │
# └───────────────────────────────────────────────────────────────────────────┘
echo "→ Suppression de $TMP_DIR…"
rm -rf "$TMP_DIR"
echo "→ Dossier temporaire supprimé."

# ┌───────────────────────────────────────────────────────────────────────────┐
# │ 6) Lancer immédiatement gitkey-install (prompt credentials)                │
# └───────────────────────────────────────────────────────────────────────────┘
echo
echo "————————————————————————————"
echo "→ Lancement de $DEST_DIR/$LOCAL_SCRIPT_NAME…"
echo "   (vous allez être invité à entrer vos identifiants GitHub)"
echo "————————————————————————————"
bash "$DEST_DIR/$LOCAL_SCRIPT_NAME"
echo
echo "→ gitexe.sh terminé."
exit 0
