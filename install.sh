#!/usr/bin/env bash
set -euo pipefail

# ───────────── Demande du nom d’utilisateur GitHub ─────────────
while true; do
  read -rp "➤ Entrez votre nom d’utilisateur GitHub (username) : " GITHUB_USER < /dev/tty
  if [[ -n "$GITHUB_USER" ]]; then
    echo "→ Nom d’utilisateur GitHub défini : $GITHUB_USER"
    break
  else
    echo "⚠ Le nom d’utilisateur ne peut pas être vide. Réessayez."
  fi
done

# … installation de git & gh …

# ───────────── Demande du token GitHub ─────────────
while true; do
  read -rp "➤ Entrez votre token GitHub (sera lu en mémoire uniquement) : " GITHUB_TOKEN < /dev/tty
  if [[ -n "$GITHUB_TOKEN" ]]; then
    echo "$GITHUB_TOKEN" | gh auth login --with-token
    echo "✔ Authentification GitHub CLI réussie."
    break
  else
    echo "⚠ Le token ne peut pas être vide. Réessayez."
  fi
done

# … suite du script (SSH, git config, etc.) …
