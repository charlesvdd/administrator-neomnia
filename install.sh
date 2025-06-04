#!/usr/bin/env bash
#===============================================================================
#
# step1-github.sh — Récupération de GITHUB_USER et GITHUB_TOKEN (interactif ou via env)
#
#===============================================================================

set -euo pipefail

# 1) Si GITHUB_USER est déjà défini au lancement, on le conserve, sinon on demande
if [[ -z "${GITHUB_USER:-}" ]]; then
  # mode interactif : boucle tant que vide
  while true; do
    read -rp "➤ Entrez votre nom d’utilisateur GitHub (username) : " GITHUB_USER
    if [[ -n "$GITHUB_USER" ]]; then
      break
    else
      echo "⚠ Le nom d’utilisateur ne peut pas être vide. Veuillez réessayer."
    fi
  done
else
  echo "→ GITHUB_USER détecté via variable d’environnement : $GITHUB_USER"
fi

# 2) Si GITHUB_TOKEN est déjà défini, on le conserve, sinon on demande
if [[ -z "${GITHUB_TOKEN:-}" ]]; then
  echo
  echo "Maintenant, on a besoin de votre token GitHub pour authentifier 'gh'."
  echo "Si vous préférez, avant d’exécuter ce script, vous pouvez exporter :" 
  echo "    export GITHUB_TOKEN=votre_token_ici"
  echo "Sinon, le script vous invitera à le coller ci-dessous."
  echo

  # boucle de saisie
  while true; do
    read -rp "➤ Entrez votre token GitHub (sera lu en mémoire seulement) : " GITHUB_TOKEN
    if [[ -n "$GITHUB_TOKEN" ]]; then
      break
    else
      echo "⚠ Le token ne peut pas être vide. Veuillez réessayer."
    fi
  done
else
  echo "→ GITHUB_TOKEN détecté via variable d’environnement (non affiché pour sécurité)."
fi

# 3) Affichage final (pour vérification) – ne pas afficher le token complet en clair
echo
echo "----------------------------------------"
echo "Nom d’utilisateur GitHub : $GITHUB_USER"
echo "Token GitHub          : ******** (déjà en mémoire)"
echo "----------------------------------------"
echo

# 4) On peut exporter ces valeurs pour les scripts suivants, par exemple :
#    export GITHUB_USER GITHUB_TOKEN
# Vous pouvez ensuite faire :
#    gh auth login --with-token <<< "$GITHUB_TOKEN"
# Ou toute autre commande qui a besoin de ces deux variables.
