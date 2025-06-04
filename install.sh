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
#   Script : setup-github.sh                                                   #
#   Auteur : Charles van den Driessche <www.neomnia.net>                       #
#   Licence: GNU General Public License v3.0                                   #
#            Voir le fichier LICENSE ou https://www.gnu.org/licenses/gpl-3.0   #
#   Année  : 2025                                                              #
#                                                                              #
################################################################################

# Couleurs pour le texte
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # Pas de couleur

set -e

# Affiche une bannière stylisée au lancement
print_banner() {
  echo -e "${CYAN}"
  echo "──────────────────────────────────────────────────────────────────────────────"
  echo "                           Installation Git & GitHub CLI                       "
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
      echo -e "${YELLOW}ℹ️  Impossible de détecter apt-get. Vérifiez manuellement la mise à jour.${NC}"
    fi
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    if command -v brew &>/dev/null; then
      echo "  - Mise à jour de Homebrew..."
      brew update >/dev/null
      echo "  - Mise à niveau des formules installées..."
      brew upgrade >/dev/null
      echo -e "${GREEN}✔ Système macOS mis à jour via Homebrew.${NC}"
    else
      echo -e "${YELLOW}ℹ️  Homebrew non installé. Passez la mise à jour macOS.${NC}"
    fi
  else
    echo -e "${YELLOW}ℹ️  Système non reconnu pour la mise à jour automatique. Passez cette étape.${NC}"
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
        wget -qO /tmp/gh.deb https://github.com/cli/cli/releases/latest/download/gh_${ARCH}_deb.deb
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

# 2. Demander le nom d'utilisateur GitHub
ask_username() {
  echo -e "${CYAN}➤ Configuration du nom d'utilisateur GitHub${NC}"
  read -rp "   Entrez votre nom d'utilisateur GitHub (ex. monLoginGitHub) : " GITHUB_USER
  if [[ -z "$GITHUB_USER" ]]; then
    error "Le nom d'utilisateur ne peut pas être vide."
  fi
  echo -e "   Nom d'utilisateur GitHub : ${YELLOW}$GITHUB_USER${NC}"
  echo
}

# 3. Générer ou importer une clé SSH
setup_ssh_key() {
  echo -e "${CYAN}➤ Configuration de la clé SSH${NC}"
  SSH_DIR="$HOME/.ssh"
  mkdir -p "$SSH_DIR"
  chmod 700 "$SSH_DIR"

  DEFAULT_KEY="$SSH_DIR/id_rsa"
  if [[ -f "$DEFAULT_KEY" ]]; then
    echo "   • Une clé SSH existe déjà à $DEFAULT_KEY."
    read -rp "     [r]égénérer une nouvelle clé ou [u]tiliser l'existante ? [r/U] : " choice
    choice=${choice,,}
    if [[ "$choice" == "r" ]]; then
      rm -f "$DEFAULT_KEY" "$DEFAULT_KEY.pub"
      echo "     Clé précédente supprimée."
    else
      echo -e "${GREEN}✔ On garde la clé SSH existante (${DEFAULT_KEY}).${NC}"
      echo
      return
    fi
  fi

  read -rp "   Entrez votre e-mail GitHub (pour la clé SSH) : " GITHUB_EMAIL
  if [[ -z "$GITHUB_EMAIL" ]]; then
    error "L'adresse e-mail ne peut pas être vide."
  fi

  echo "   Génération d'une nouvelle paire de clés SSH (RSA 4096 bits)..."
  ssh-keygen -t rsa -b 4096 -C "$GITHUB_EMAIL" -f "$DEFAULT_KEY" -N "" -q
  echo -e "${GREEN}✔ Clé SSH générée :${NC} ${DEFAULT_KEY} (+ .pub)"
  echo
}

# 4. Ajouter la clé SSH sur GitHub via gh
add_ssh_key_to_github() {
  echo -e "${CYAN}➤ Ajout de la clé SSH sur GitHub${NC}"
  PUB_KEY_PATH="$HOME/.ssh/id_rsa.pub"
  [[ -f "$PUB_KEY_PATH" ]] || error "Clé publique SSH introuvable à $PUB_KEY_PATH."

  echo "   • Affichage de la clé publique :"
  echo "──────────────────────────────────────────────────────────────────────────────"
  cat "$PUB_KEY_PATH"
  echo "──────────────────────────────────────────────────────────────────────────────"
  echo "   • Cette clé va être ajoutée à votre compte GitHub."
  echo

  # Authentification via gh si nécessaire
  if gh auth status &>/dev/null; then
    echo -e "${GREEN}✔ Vous êtes déjà authentifié avec gh.${NC}"
  else
    echo "   Vous n'êtes pas encore authentifié. Lancement de l'authentification via navigateur..."
    gh auth login --hostname github.com --web
  fi

  KEY_TITLE="clé-ssh-$(date +'%Y-%m-%d_%H-%M-%S')"
  echo "   Ajout de la clé SSH à GitHub sous le titre : ${YELLOW}$KEY_TITLE${NC}"
  gh ssh-key add "$PUB_KEY_PATH" -t "$KEY_TITLE" >/dev/null
  echo -e "${GREEN}✔ Clé SSH ajoutée avec succès à votre compte GitHub.${NC}"
  echo
}

# 5. Configurer Git (user.name et user.email)
configure_git() {
  echo -e "${CYAN}➤ Configuration basique de Git${NC}"
  read -rp "   Entrez votre nom complet (pour git config user.name) : " GIT_FULLNAME
  read -rp "   Entrez votre e-mail (pour git config user.email) : " GIT_EMAIL

  if [[ -n "$GIT_FULLNAME" ]]; then
    git config --global user.name "$GIT_FULLNAME"
    echo -e "   user.name défini à : ${YELLOW}$GIT_FULLNAME${NC}"
  fi
  if [[ -n "$GIT_EMAIL" ]]; then
    git config --global user.email "$GIT_EMAIL"
    echo -e "   user.email défini à : ${YELLOW}$GIT_EMAIL${NC}"
  fi

  echo -e "${GREEN}✔ Configuration Git actuelle (global) :${NC}"
  git config --global --list
  echo
}

# 6. Vérification finale (clone/accès SSH)
final_gh_login() {
  echo -e "${CYAN}➤ Vérification finale de l'accès GitHub${NC}"
  echo "   Pour tester l'accès SSH, le script va tenter de lister vos dépôts :"
  if gh repo list "$GITHUB_USER" &>/dev/null; then
    echo -e "${GREEN}✔ Connexion réussie ! Voici la liste de vos dépôts :${NC}"
    gh repo list "$GITHUB_USER"
  else
    echo -e "${RED}✖ Impossible d'accéder à vos dépôts via SSH.${NC}"
    echo "   Vérifiez que la clé SSH a bien été ajoutée sur GitHub ou relancez :"
    echo -e "     ${YELLOW}gh auth login${NC}"
  fi
  echo
}

# Exécution séquentielle des étapes
print_banner
update_system
install_tools
ask_username
setup_ssh_key
add_ssh_key_to_github
configure_git
final_gh_login

echo -e "${GREEN}🌟 Tout est configuré ! Vous pouvez maintenant utiliser git et GitHub depuis la CLI.${NC}"
