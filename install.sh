#!/usr/bin/env bash
set -euo pipefail

# 1) Demande du nom d'utilisateur GitHub
read -rp "➤ Entrez votre nom d’utilisateur GitHub (username) : " GITHUB_USER
if [[ -z "$GITHUB_USER" ]]; then
  echo "Erreur : nom d’utilisateur vide."
  exit 1
fi
echo "→ Nom d’utilisateur GitHub défini : $GITHUB_USER"

# 2) Mise à jour / installation de Git & gh (par ex.)
echo "→ Installation de Git et GitHub CLI..."
sudo apt-get update -y
sudo apt-get install -y git curl

# Ajout du repo gh + installation
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
  | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
https://cli.github.com/packages stable main" \
  | sudo tee /etc/apt/sources.list.d/gh-cli.list >/dev/null
sudo apt-get update -y
sudo apt-get install -y gh
echo "✔ Git et gh installés."

# 3) Demande du token GitHub
read -rp "➤ Entrez votre token GitHub (il restera en mémoire le temps de l'exécution) : " GITHUB_TOKEN
if [[ -z "$GITHUB_TOKEN" ]]; then
  echo "⚠ Aucune clé fournie. Vous pourrez exécuter 'gh auth login' plus tard."
else
  echo "$GITHUB_TOKEN" | gh auth login --with-token
  echo "✔ Authentification gh réussie."
fi

# … Suite du script (config SSH, configuration git, etc.)
