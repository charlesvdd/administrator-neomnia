#!/usr/bin/env bash
set -euo pipefail

# ┌───────────────────────────────────────────────────────────────────────────┐
# │ 1) Définir où cloner temporairement le dépôt                            │
# └───────────────────────────────────────────────────────────────────────────┘
TMP_DIR="/var/github-temp"
REPO_URL="https://github.com/charlesvdd/administrator-neomnia.git"
BRANCH="api-key-github"

# S’il existe déjà, on supprime pour repartir “propre”
if [ -d "$TMP_DIR" ]; then
  rm -rf "$TMP_DIR"
fi

# ┌───────────────────────────────────────────────────────────────────────────┐
# │ 2) Cloner le dépôt dans /var/github-temp                                 │
# └───────────────────────────────────────────────────────────────────────────┘
echo "→ Clonage du dépôt dans $TMP_DIR…"
git clone --branch "$BRANCH" "$REPO_URL" "$TMP_DIR"

# ┌───────────────────────────────────────────────────────────────────────────┐
# │ 3) Exécuter install.sh en local (stdin connecté au terminal)             │
# └───────────────────────────────────────────────────────────────────────────┘
echo "→ Exécution de install.sh…"
chmod +x "$TMP_DIR/install.sh"
bash "$TMP_DIR/install.sh"

# ┌───────────────────────────────────────────────────────────────────────────┐
# │ 4) Nettoyage du clone : on supprime le dossier temporaire                │
# └───────────────────────────────────────────────────────────────────────────┘
echo "→ Suppression du dossier temporaire $TMP_DIR…"
rm -rf "$TMP_DIR"

# ┌───────────────────────────────────────────────────────────────────────────┐
# │ 5) Demande des identifiants GitHub                                        │
# └───────────────────────────────────────────────────────────────────────────┘
echo
echo "------------------------------"
echo "🛠  Veuillez entrer vos identifiants GitHub"
echo "------------------------------"
read -p "Utilisateur GitHub : " GITHUB_USER
read -s -p "Token ou mot de passe GitHub : " GITHUB_TOKEN
echo
echo "→ Identifiants saisis (le token reste masqué)."

# ┌───────────────────────────────────────────────────────────────────────────┐
# │ 6) Stocker ces identifiants dans un fichier de configuration              │
# └───────────────────────────────────────────────────────────────────────────┘
CONFIG_DIR="$HOME/.neomnia"
mkdir -p "$CONFIG_DIR"
cat > "$CONFIG_DIR/credentials.conf" <<EOF
GITHUB_USER="$GITHUB_USER"
GITHUB_TOKEN="$GITHUB_TOKEN"
EOF
echo "→ Vos identifiants GitHub ont été enregistrés dans $CONFIG_DIR/credentials.conf"

# ┌───────────────────────────────────────────────────────────────────────────┐
# │ 7) Suppression du script lui-même                                         │
# └───────────────────────────────────────────────────────────────────────────┘
echo "→ Suppression de ce script (self-delete)…"
rm -- "$0"

# Note : à partir d’ici, tout est terminé. Le seul résidu est ~/.neomnia/credentials.conf
