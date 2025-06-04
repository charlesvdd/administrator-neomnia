#!/usr/bin/env bash

################################################################################
#                                                                              #
#   ██████╗ ███████╗████████╗ ██████╗ ██╗   ██╗███╗   ███╗ █████╗             #
#   ██╔══██╗██╔════╝╚══██╔══╝██╔═══██╗██║   ██║████╗ ████║██╔══██╗            #
#   ██████╔╝█████╗     ██║   ██║   ██║██║   ██║██╔████╔██║███████║            #
#   ██╔══██╗██╔══╝     ██║   ██║   ██║██║   ██║██║╚██╔╝██║██╔══██║            #
#   ██████╔╝███████╗   ██║   ╚██████╔╝╚██████╔╝██║ ╚═╝ ██║██║  ██║            #
#   ╚═════╝ ╚══════╝   ╚═╝    ╚═════╝  ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝            #
#                                                                              #
#   Script : install.sh                                                        #
#   Auteur : Charles van den Driessche                                          #
#   Licence: GNU General Public License v3.0                                   #
#   Année  : 2025                                                              #
#                                                                              #
################################################################################

# Couleurs pour le texte
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # Pas de couleur

set -euo pipefail

# Affiche une bannière stylisée au lancement
print_banner() {
  echo -e "${CYAN}"
  echo "──────────────────────────────────────────────────────────────────────────────"
  echo "                           Installation Git & GitHub CLI                      "
  echo "──────────────────────────────────────────────────────────────────────────────"
  echo -e "${NC}"
  echo -e "${YELLOW}Auteur   : Charles van den Driessche${NC}"
  echo -e "${YELLOW}Site Web : https://www.neomnia.net${NC}"
  echo -e "${YELLOW}Licence  : GNU GPL v3${NC}"
  echo
}

# Fonction pour afficher un message d'erreur puis quitter
error() {
  echo -e "${RED}Erreur : $1${NC}" >&2
  exit 1
}

# 0. Mise à jour du système (packages)
update_system() {
  echo -e "${CYAN}➤ Mise à jour du système${NC}"
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if command -v apt-get &>/dev/null; then
      echo "  - Mise à jour des listes de paquets (apt-get update)..."
      sudo apt-get update -qq
      echo "  - Mise à niveau des paquets installés (apt-get upgrade)..."
      sudo apt-get upgrade -y -qq
      echo -e "${GREEN}✔ Système Linux mis à jour.${NC}"
    else
      echo -e "${YELLOW}ℹ️  Impossible de détecter apt-get. Passez manuellement cette étape.${NC}"
    fi
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    if command -v brew &>/dev/null; then
      echo "  - Mise à jour de Homebrew..."
      brew update >/dev/null
      echo "  - Mise à niveau des formules installées..."
      brew upgrade >/dev/null
      echo -e "${GREEN}✔ Système macOS mis à jour via Homebrew.${NC}"
    else
      echo -e "${YELLOW}ℹ️  Homebrew non installé. Passez manuellement cette étape.${NC}"
    fi
  else
    echo -e "${YELLOW}ℹ️  OS non reconnu pour mise à jour automatique. Passez manuellement.${NC}"
  fi
  echo
}

# 1. Installer Git et GitHub CLI (gh)
install_tools() {
  echo -e "${CYAN}➤ Installation de Git et GitHub CLI${NC}"
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if command -v apt-get &>/dev/null; then
      echo "  - Détection Ubuntu/Debian (apt-get)."
      sudo apt-get install -y git curl wget -qq
      if ! command -v gh &>/dev/null; then
        echo "  - Téléchargement et installation de GitHub CLI (gh)..."
        ARCH=$(uname -m)
        wget -qO /tmp/gh.deb "https://github.com/cli/cli/releases/latest/download/gh_${ARCH}_deb.deb"
        sudo dpkg -i /tmp/gh.deb &>/dev/null || sudo apt-get install -f -y -qq
        rm -f /tmp/gh.deb
      else
        echo "  - GitHub CLI (gh) est déjà installé."
      fi
    else
      error "Distribution Linux non prise en charge automatiquement. Installez manuellement git et gh."
    fi

  elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo "  - Détection macOS (Homebrew)."
    if ! command -v brew &>/dev/null; then
      echo "    • Homebrew introuvable. Installation de Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    echo "  - Installation de git et gh via Homebrew..."
    brew install git gh >/dev/null
  else
    error "OS non pris en charge automatiquement. Installez manuellement git et la CLI GitHub (gh)."
  fi

  # Vérification
  if ! command -v git &>/dev/null; then
    error "L'installation de git a échoué."
  fi
  if ! command -v gh &>/dev/null; then
    error "L'installation de gh (GitHub CLI) a échoué."
  fi

  echo -e "${GREEN}✔ Git ($(git --version)) et GitHub CLI ($(gh --version | head -n1)) sont prêts.${NC}"
  echo
}

# 2. Récupérer le GitHub API token depuis variable ou prompt
ask_token() {
  echo -e "${CYAN}➤ Configuration du GitHub API token${NC}"
  if [[ -n "${GITHUB_TOKEN-}" ]]; then
    echo "   Token GitHub pris depuis la variable d’environnement."
  else
    read -rp "   Entrez votre GitHub API token (PAT, scope repo) : " GITHUB_TOKEN
    if [[ -z "$GITHUB_TOKEN" ]]; then
      error "Le token ne peut pas être vide."
    fi
  fi
  echo
}

# 3. Authentifier GH CLI avec le token
authenticate_gh() {
  echo -e "${CYAN}➤ Authentification GitHub CLI${NC}"
  echo "$GITHUB_TOKEN" | gh auth login --with-token
  echo -e "${GREEN}✔ GH CLI authentifié avec le token fourni.${NC}"
  echo
}

# 4. Configurer Git (user.name et user.email depuis variables ou prompt)
configure_git() {
  echo -e "${CYAN}➤ Configuration basique de Git${NC}"
  if [[ -n "${GIT_FULLNAME-}" ]]; then
    git config --global user.name "$GIT_FULLNAME"
    echo -e "   user.name défini depuis la variable : ${YELLOW}$GIT_FULLNAME${NC}"
  else
    read -rp "   Entrez votre nom complet (pour git config user.name) : " GIT_FULLNAME
    if [[ -n "$GIT_FULLNAME" ]]; then
      git config --global user.name "$GIT_FULLNAME"
      echo -e "   user.name défini à : ${YELLOW}$GIT_FULLNAME${NC}"
    fi
  fi

  if [[ -n "${GIT_EMAIL-}" ]]; then
    git config --global user.email "$GIT_EMAIL"
    echo -e "   user.email défini depuis la variable : ${YELLOW}$GIT_EMAIL${NC}"
  else
    read -rp "   Entrez votre e-mail (pour git config user.email) : " GIT_EMAIL
    if [[ -n "$GIT_EMAIL" ]]; then
      git config --global user.email "$GIT_EMAIL"
      echo -e "   user.email défini à : ${YELLOW}$GIT_EMAIL${NC}"
    fi
  fi

  echo -e "${GREEN}✔ Configuration Git actuelle (global) :${NC}"
  git config --global --list
  echo
}

# 5. Vérification finale (liste des repos via GH)
final_gh_login() {
  echo -e "${CYAN}➤ Vérification finale de l'accès GitHub${NC}"
  echo "   Pour tester l'accès, le script va tenter de lister vos dépôts :"
  GH_USER="$(gh api /user --jq .login)"
  if gh repo list "$GH_USER" &>/dev/null; then
    echo -e "${GREEN}✔ Connexion réussie ! Voici la liste de vos dépôts :${NC}"
    gh repo list "$GH_USER"
  else
    echo -e "${RED}✖ Impossible d'accéder à vos dépôts via le token.${NC}"
    echo "   Vérifiez que le token a le scope 'repo' et réessayez."
  fi
  echo
}

# Exécution séquentielle des étapes
print_banner
update_system
install_tools
ask_token
authenticate_gh
configure_git
final_gh_login

echo -e "${GREEN}🌟 Tout est configuré ! Vous pouvez maintenant utiliser Git et GitHub CLI via le token.${NC}"
