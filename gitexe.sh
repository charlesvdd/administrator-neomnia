#!/usr/bin/env bash
set -euo pipefail

# ┌───────────────────────────────────────────────────────────────────────────┐
# │ 1) Variables                                                          │
# └───────────────────────────────────────────────────────────────────────────┘
TMP_DIR="/var/github-repo-temp"
REPO_URL="https://github.com/charlesvdd/administrator-neomnia.git"
BRANCH="api-key-github"

DEST_DIR="/usr/local/bin"
LOCAL_SCRIPT_NAME="gitkey-install"       # <– nouveau nom du script en local

# ┌───────────────────────────────────────────────────────────────────────────┐
# │ 2) Nettoyage de TM P_DIR si nécessaire                                 │
# └───────────────────────────────────────────────────────────────────────────┘
if [ -d "$TMP_DIR" ]; then
  echo "→ Suppression de l’ancien dossier temporaire $TMP_DIR"
  rm -rf "$TMP_DIR"
fi

# ┌───────────────────────────────────────────────────────────────────────────┐
# │ 3) Clonage du dépôt GitHub dans TMP_DIR                                 │
# └───────────────────────────────────────────────────────────────────────────┘
echo "→ Clonage du dépôt Git dans $TMP_DIR (branche '$BRANCH')…"
git clone --branch "$BRANCH" "$REPO_URL" "$TMP_DIR"
echo "→ Clone terminé."

# ┌───────────────────────────────────────────────────────────────────────────┐
# │ 4) Vérifier l’existence de gitkey-install et le copier                   │
# └───────────────────────────────────────────────────────────────────────────┘
if [ ! -f "$TMP_DIR/$LOCAL_SCRIPT_NAME" ]; then
  echo "‼️  Erreur : $LOCAL_SCRIPT_NAME introuvable dans le dépôt."
  echo "    Vérifiez que le dépôt contient bien ce fichier à la racine."
  exit 1
fi

# Copier le script dans DEST_DIR
mkdir -p "$DEST_DIR"
echo "→ Copie de $LOCAL_SCRIPT_NAME vers $DEST_DIR/$LOCAL_SCRIPT_NAME…"
cp "$TMP_DIR/$LOCAL_SCRIPT_NAME" "$DEST_DIR/$LOCAL_SCRIPT_NAME"
chmod +x "$DEST_DIR/$LOCAL_SCRIPT_NAME"
echo "→ Copie et chmod +x de $LOCAL_SCRIPT_NAME réussis."

# ┌───────────────────────────────────────────────────────────────────────────┐
# │ 5) Suppression du clone temporaire                                       │
# └───────────────────────────────────────────────────────────────────────────┘
echo "→ Suppression de $TMP_DIR…"
rm -rf "$TMP_DIR"
echo "→ Dossier temporaire supprimé."

# ┌───────────────────────────────────────────────────────────────────────────┐
# │ 6) Lancer immédiatement gitkey-install (prompt credentials)              │
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
