#!/usr/bin/env bash
set -euo pipefail

# 1) Demande manuelle du nom d’utilisateur GitHub
while true; do
  read -rp "➤ Entrez votre nom d’utilisateur GitHub (username) : " GITHUB_USER
  if [[ -n "$GITHUB_USER" ]]; then
    echo "→ Nom d’utilisateur GitHub défini : $GITHUB_USER"
    break
  else
    echo "⚠ Le nom d’utilisateur ne peut pas être vide. Réessayez."
  fi
done

# 2) Installation de Git et de GitHub CLI (gh)
echo
echo "──────────── Installation de Git et GitHub CLI ────────────"
sudo apt-get update -y
sudo apt-get install -y git curl

# Ajout du dépôt officiel et installation de gh
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
  | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
https://cli.github.com/packages stable main" \
  | sudo tee /etc/apt/sources.list.d/gh-cli.list >/dev/null
sudo apt-get update -y
sudo apt-get install -y gh
echo "✔ gh installé (version : $(gh --version | head -n1))"

# 3) Demande manuelle du token GitHub
echo
while true; do
  read -rp "➤ Entrez votre token GitHub (sera lu en mémoire uniquement) : " GITHUB_TOKEN
  if [[ -n "$GITHUB_TOKEN" ]]; then
    echo "$GITHUB_TOKEN" | gh auth login --with-token
    echo "✔ Authentification GitHub CLI réussie."
    break
  else
    echo "⚠ Le token ne peut pas être vide. Réessayez."
  fi
done

# 4) Suite du script (SSH, configuration git, etc.)
echo
echo "──────────── Suite de la configuration (SSH, git config…) ────────────"
# … ici, par exemple, génération de la clé SSH, config git user.name/email, etc. …
