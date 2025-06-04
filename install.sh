#!/bin/bash

# Vérifier si l'utilisateur a les droits sudo
if ! sudo -v; then
  echo "Erreur : Ce script nécessite des privilèges sudo."
  exit 1
fi

# Créer un répertoire temporaire
TMP_DIR=$(mktemp -d)

# Télécharger le script dans le répertoire temporaire
SCRIPT_URL="https://raw.githubusercontent.com/charlesvdd/administrator-neomnia/api-key-github/install.sh"
SCRIPT_PATH="$TMP_DIR/install.sh"

curl -sSL "$SCRIPT_URL" -o "$SCRIPT_PATH"

# Vérifier si le téléchargement a réussi
if [ ! -f "$SCRIPT_PATH" ]; then
    echo "Erreur : Impossible de télécharger le script."
    sudo rm -rf "$TMP_DIR"
    exit 1
fi

# Donner les permissions d'exécution
chmod +x "$SCRIPT_PATH"

# Exécuter le script avec sudo si nécessaire
sudo "$SCRIPT_PATH"

# Supprimer le répertoire temporaire et son contenu
sudo rm -rf "$TMP_DIR"

echo "Script exécuté et nettoyé."
