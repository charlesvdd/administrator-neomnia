#!/usr/bin/env bash
set -euo pipefail
# -------------------------------------------------------------------
#  react.sh — Script d'installation Next.js (TypeScript + ESLint)
#  🏢 Neomia Studio — Automatisation & Déploiement Intelligent
#  📜 Licence : Propriétaire — Charles Van den driessche (2025)
#  Objectif : Installer Next.js en mode utilisateur (sans sudo)
#             avec TypeScript, ESLint, Prettier et Git.
# -------------------------------------------------------------------

### 1. Définitions des couleurs et styles ###
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'
NEOMIA="${MAGENTA}⚡ Neomia${RESET}"

# Activer l'installation de ESLint/Prettier (désactiver avec "false")
INSTALL_ESLINT_PRETTIER=true

### 2. Fonction pour comparer les versions de Node.js (portable) ###
version_ge() {
    [ "$1" = "$2" ] && return 0
    local IFS=.
    local i ver1=($1) ver2=($2)
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++)); do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++)); do
        if [[ -z ${ver2[i]} ]]; then
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]})); then
            return 0
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]})); then
            return 1
        fi
    done
    return 0
}

### 3. Fonction pour installer Prettier/ESLint ###
install_linters() {
    echo -e "${NEOMIA} ${DIM}→ Configuration des linters...${RESET}"
    if ! grep -q '"prettier"' package.json; then
        echo -e "${BLUE}➜ Installation de Prettier + plugins ESLint...${RESET}"
        npm install --save-dev prettier eslint-config-prettier eslint-plugin-react eslint-plugin-react-hooks --loglevel=error
        echo -e "${GREEN}   • ${NEOMIA} Prettier & ESLint installés.${RESET}"
    else
        echo -e "${GREEN}   • ${NEOMIA} Prettier/ESLint déjà présents.${RESET}"
    fi
}

### 4. Bannière Neomia Studio ###
echo -e "${CYAN}${BOLD}"
cat << "EOF"
  _   _ _____ _____ _____ ____  _   _
 | \ | |_   _|_   _|_   _|  _ \| | | |
 |  \| | | |   | |   | | | |_) | | | |
 | |\  | | |   | |   | | |  __/| |_| |
 |_| \_| |_|   |_|   |_| |_|    \___/
   🚀  NEXT.JS INSTALLER — POWERED BY NEOMIA STUDIO  🚀
EOF
echo -e "${RESET}"
sleep 1

### 5. Détecter/Installer NVM ###
echo -e "${NEOMIA} ${DIM}Étape 1/6 : Vérification de NVM...${RESET}"
if [ -d "$HOME/.nvm" ] && [ -s "$HOME/.nvm/nvm.sh" ]; then
    echo -e "${GREEN}   • ${NEOMIA} NVM est déjà installé.${RESET}"
else
    echo -e "${BLUE}➜ Installation de NVM...${RESET}"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    if ! [ -s "$NVM_DIR/nvm.sh" ]; then
        echo -e "${RED}❗ ${NEOMIA} Échec de l'installation de NVM.${RESET}"
        exit 1
    fi
    echo -e "${GREEN}   • ${NEOMIA} NVM installé avec succès.${RESET}"
fi
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

### 6. Installer/Mettre à jour Node.js ###
echo -e "${NEOMIA} ${DIM}Étape 2/6 : Configuration de Node.js...${RESET}"
NODE_MIN_VERSION="18.0.0"
if command -v node &>/dev/null; then
    CURRENT_NODE_VERSION="$(node -v | sed 's/^v//')"
    if version_ge "$CURRENT_NODE_VERSION" "$NODE_MIN_VERSION"; then
        echo -e "${GREEN}   • ${NEOMIA} Node.js v${CURRENT_NODE_VERSION} (≥ ${NODE_MIN_VERSION}) est prêt.${RESET}"
    else
        echo -e "${YELLOW}⚠️  ${NEOMIA} Mise à jour de Node.js...${RESET}"
        nvm install 18 --no-progress
        nvm alias default 18
    fi
else
    echo -e "${BLUE}➜ Installation de Node.js v18...${RESET}"
    nvm install 18 --no-progress
    nvm alias default 18
fi
echo -e "${CYAN}   • ${NEOMIA} node: $(node -v)${RESET}    ${CYAN}npm: $(npm -v)${RESET}"

### 7. Demander le nom du projet ###
echo -e "${NEOMIA} ${DIM}Étape 3/6 : Configuration du projet...${RESET}"
echo -ne "${MAGENTA}➜ Nom du projet (ex: mon-app) : ${RESET}"
read -r PROJECT_NAME
if [ -z "$PROJECT_NAME" ] || ! [[ "$PROJECT_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo -e "${RED}❗ ${NEOMIA} Nom invalide. Utilisez [a-zA-Z0-9_-].${RESET}"
    exit 1
fi

### 8. Préparer le dossier ~/opt/<projet> ###
echo -e "${NEOMIA} ${DIM}Étape 4/6 : Préparation du dossier...${RESET}"
BASE_DIR="$HOME/opt"
PROJECT_DIR="$BASE_DIR/$PROJECT_NAME"
mkdir -p "$BASE_DIR"
if [ -d "$PROJECT_DIR" ]; then
    echo -e "${YELLOW}⚠️  ${NEOMIA} Le dossier '$PROJECT_DIR' existe.${RESET}"
    if [ -f "$PROJECT_DIR/package.json" ]; then
        echo -e "${GREEN}   • ${NEOMIA} Projet existant détecté. Mise à jour...${RESET}"
        cd "$PROJECT_DIR"
        npm install --loglevel=error
        install_linters
        if [ -d ".git" ]; then
            echo -e "${GREEN}   • ${NEOMIA} Dépôt Git existant.${RESET}"
        else
            echo -e "${BLUE}➜ Initialisation Git...${RESET}"
            git init && git add . && git commit -m "Mise à jour par Neomia Studio" > /dev/null
        fi
        echo -e "${GREEN}✅ ${NEOMIA} Projet '$PROJECT_NAME' mis à jour.${RESET}"
        exit 0
    else
        echo -ne "${YELLOW}❓ ${NEOMIA} Supprimer et recréer ? (o/N) : ${RESET}"
        read -r RESP
        if [[ "$RESP" =~ ^[oO]$ ]]; then
            rm -rf "$PROJECT_DIR"
            echo -e "${GREEN}   • ${NEOMIA} Dossier supprimé.${RESET}"
        else
            echo -e "${RED}❌ ${NEOMIA} Abandon.${RESET}"
            exit 1
        fi
    fi
fi

### 9. Créer le projet Next.js ###
echo -e "${NEOMIA} ${DIM}Étape 5/6 : Génération du projet...${RESET}"
cd "$BASE_DIR"
echo -e "${BLUE}➜ Création du squelette Next.js (TypeScript + ESLint)...${RESET}"
npx create-next-app@latest "$PROJECT_NAME" --typescript --eslint 2>&1 | grep -v "success" || true
cd "$PROJECT_DIR"
npm install --loglevel=error
install_linters

### 10. Initialiser Git ###
echo -e "${NEOMIA} ${DIM}Étape 6/6 : Finalisation...${RESET}"
if [ ! -d ".git" ]; then
    git init
    git add .
    git commit -m "Initial commit — Setup Next.js par Neomia Studio" > /dev/null
    echo -e "${GREEN}   • ${NEOMIA} Git initialisé.${RESET}"
fi

### 11. Instructions finales ###
DEFAULT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
echo -e "${GREEN}${BOLD}
✅ ${NEOMIA} Projet '$PROJECT_NAME' prêt dans ~/opt !
${RESET}"
echo -e "${CYAN}   • Lancer le serveur :
    cd ~/opt/$PROJECT_NAME && npm run dev
   • Ajouter un remote Git :
    git remote add origin <votre-repo>
    git push -u origin $DEFAULT_BRANCH
${RESET}"
echo -e "${MAGENTA}   🎨 Développé avec amour par Neomia Studio.${RESET}"
