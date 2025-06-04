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
  echo "                           Configuration Git & GitHub CLI                   "
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

# 1. Installer GitHub CLI si absent
install_gh_cli() {
  if ! command -v gh &>/dev/null; then
    echo -e "${CYAN}➤ Installation de GitHub CLI (gh)${NC}"
    if [[ "$OSTYPE" == "linux-gnu"* ]] && command -v apt-get &>/dev/null; then
      sudo apt-get install -y gh -qq
    elif [[ "$OSTYPE" == "darwin"* ]] && command -v brew &>/dev/null; then
      brew install gh >/dev/null
    else
      error "Impossible d’installer gh automatiquement. Installez-le manuellement."
    fi
    echo -e "${GREEN}✔ GitHub CLI installé.${NC}"
  else
    echo -e "${CYAN}➤ GitHub CLI déjà présent.${NC}"
  fi
  echo
}

# 2. Récupérer le GitHub username et token (PAT) depuis variables ou prompt
ask_credentials() {
  echo -e "${CYAN}➤ Configuration des identifiants GitHub${NC}"

  # Username
  if [[ -n "${GITHUB_USER-}" ]]; then
    echo "   Nom d’utilisateur GitHub pris depuis la variable : ${YELLOW}$GITHUB_USER${NC}"
  else
    read -rp "   Entrez votre nom d’utilisateur GitHub : " GITHUB_USER
    [[ -n "$GITHUB_USER" ]] || error "Le nom d’utilisateur ne peut pas être vide."
  fi

  # Token
  if [[ -n "${GITHUB_TOKEN-}" ]]; then
    echo "   Token GitHub pris depuis la variable d’environnement."
  else
    read -rp "   Entrez votre GitHub API token (PAT, avec scope repo) : " GITHUB_TOKEN
    [[ -n "$GITHUB_TOKEN" ]] || error "Le token ne peut pas être vide."
  fi

  echo
}

# 3. Authentifier GH CLI avec le token
authenticate_gh() {
  echo -e "${CYAN}➤ Authentification GitHub CLI via token${NC}"
  echo "$GITHUB_TOKEN" | gh auth login --with-token
  echo -e "${GREEN}✔ GH CLI authentifié pour $GITHUB_USER.${NC}"
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
    [[ -n "$GIT_FULLNAME" ]] && git config --global user.name "$GIT_FULLNAME"
    echo -e "   user.name défini à : ${YELLOW}$GIT_FULLNAME${NC}"
  fi

  if [[ -n "${GIT_EMAIL-}" ]]; then
    git config --global user.email "$GIT_EMAIL"
    echo -e "   user.email défini depuis la variable : ${YELLOW}$GIT_EMAIL${NC}"
  else
    read -rp "   Entrez votre e-mail (pour git config user.email) : " GIT_EMAIL
    [[ -n "$GIT_EMAIL" ]] && git config --global user.email "$GIT_EMAIL"
    echo -e "   user.email défini à : ${YELLOW}$GIT_EMAIL${NC}"
  fi

  echo -e "${GREEN}✔ Configuration Git actuelle (global) :${NC}"
  git config --global --list
  echo
}

# 5. Vérification finale (liste des repos via GH CLI)
final_gh_login() {
  echo -e "${CYAN}➤ Vérification finale : liste des dépôts${NC}"
  if gh auth status &>/dev/null; then
    echo "   Tentative de lister les dépôts de $GITHUB_USER..."
    gh repo list "$GITHUB_USER" || error "Échec de la liste des dépôts."
    echo -e "${GREEN}✔ Requête réussie : vous êtes bien connecté(e).${NC}"
  else
    error "Authentification GH CLI échouée."
  fi
  echo
}

# Exécution
print_banner
install_gh_cli
ask_credentials
authenticate_gh
configure_git
final_gh_login

echo -e "${GREEN}🌟 Tout est configuré ! Vous pouvez maintenant utiliser Git & GitHub CLI via le token.${NC}"
