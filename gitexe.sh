#!/usr/bin/env bash
set -euo pipefail

# ┌───────────────────────────────────────────────────────────────────────────┐
# │ 1) Variables                                                             │
# └───────────────────────────────────────────────────────────────────────────┘
# Répertoire temporaire pour cloner le dépôt
TMP_DIR="/var/github-repo-temp"
# URL complète vers votre dépôt GitHub (branche “api-key-github” ici)
REPO_URL="https://github.com/charlesvdd/administrator-neomnia.git"
BRANCH="api-key-github"

# Où installer (copier) notre second script localement
# Ici on choisit /usr/local/bin, mais vous pouvez ajuster
DEST_DIR="/usr/local/bin"
LOCAL_SCRIPT_NAME="local-install.sh"

# ┌───────────────────────────────────────────────────────────────────────────┐
# │ 2) Nettoyage si TMP_DIR existe déjà                                      │
# └───────────────────────────────────────────────────────────────────────────┘
if [ -d "$TMP_DIR" ]; then
  echo "→ Suppression de l’ancien dossier temporaire $TMP_DIR"
  rm -rf "$TMP_DIR"
fi

# ┌───────────────────────────────────────────────────────────────────────────┐
# │ 3) Clonage du dépôt Git dans TMP_DIR                                      │
# └───────────────────────────────────────────────────────────────────────────┘
echo "→ Clonage du dépôt Git dans $TMP_DIR (branche '$BRANCH')…"
git clone --branch "$BRANCH" "$REPO_URL" "$TMP_DIR"
echo "→ Clone terminé."

# ┌───────────────────────────────────────────────────────────────────────────┐
# │ 4) Vérifier que le second script existe et le copier en local             │
# └───────────────────────────────────────────────────────────────────────────┘
# On suppose que dans le dépôt, vous avez un fichier nommé local-install.sh
if [ ! -f "$TMP_DIR/$LOCAL_SCRIPT_NAME" ]; then
  echo "‼️  Erreur : $LOCAL_SCRIPT_NAME introuvable dans le dépôt."
  echo "    Vérifiez que le dépôt contient bien ce fichier à la racine."
  exit 1
fi

# Copier le script dans DEST_DIR (création du dossier si nécessaire)
mkdir -p "$DEST_DIR"
echo "→ Copie de $LOCAL_SCRIPT_NAME vers $DEST_DIR/$LOCAL_SCRIPT_NAME…" 
cp "$TMP_DIR/$LOCAL_SCRIPT_NAME" "$DEST_DIR/$LOCAL_SCRIPT_NAME"
chmod +x "$DEST_DIR/$LOCAL_SCRIPT_NAME"
echo "→ Copie et chmod +x terminés."

# ┌───────────────────────────────────────────────────────────────────────────┐
# │ 5) Supprimer le dossier temporaire                                        │
# └───────────────────────────────────────────────────────────────────────────┘
echo "→ Suppression de $TMP_DIR…"
rm -rf "$TMP_DIR"
echo "→ Dossier temporaire supprimé."

# ┌───────────────────────────────────────────────────────────────────────────┐
# │ 6) Lancer immédiatement le second script (qui va demander les credentials)│
# └───────────────────────────────────────────────────────────────────────────┘
echo
echo "————————————————————————————"
echo "→ Lancement de $DEST_DIR/$LOCAL_SCRIPT_NAME…"
echo "   (vous allez être invité à entrer vos identifiants GitHub)"
echo "————————————————————————————"
bash "$DEST_DIR/$LOCAL_SCRIPT_NAME"
echo
echo "→ fetch-and-install.sh terminé."
exit 0
