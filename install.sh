#!/usr/bin/env bash
set -euo pipefail

# ----------------------------------------------------
#  install.sh (branche next-project)
#  Objectif : Installer Next.js + TypeScript + ESLint
#             en mode utilisateur (sans sudo), dans ~/opt/<nom_du_projet>
#             Logging détaillé de chaque étape
# ----------------------------------------------------

### 1. Définitions des couleurs (pour l’affichage) ###
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
RESET='\033[0m'

LOG() {
  echo -e "${CYAN}[INFO]${RESET} $1"
}

STEP() {
  echo -e "${YELLOW}--- $1 ---${RESET}"
}

ERROR() {
  echo -e "${RED}[ERROR]${RESET} $1" >&2
}

### 2. Bannière ASCII ###
STEP "Démarrage du script d'installation"
echo -e "${CYAN}${BOLD}"
cat << "EOF"
  _   _            _   _      _       _
 | \ | | ___  __ _| \ | | ___| |_ ___| |__ ___
 |  \| |/ _ \/ _` |  \| |/ _ \ __/ __| '_ \ __|
 | |\  |  __/ (_| | |\  |  __/ || (__| | | \__ \
 |_| \_|\___|\__, |_| \_|\___|\__\___|_| |_|___/
              |___/

   🚀  INSTALLATION NEXT.JS (MODE UTILISATEUR) 🚀
EOF
echo -e "${RESET}"
sleep 1

### 3. Vérifier/installer NVM ###
STEP "Vérification de NVM"
if [ -d "$HOME/.nvm" ] && [ -s "$HOME/.nvm/nvm.sh" ]; then
  LOG "NVM déjà installé"
else
  LOG "Installation de NVM (Node Version Manager)"
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  LOG "NVM installé avec succès"
fi

# Charger NVM pour ce shell
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

### 4. Installer / mettre à jour Node.js ≥ 18 via NVM ###
NODE_MIN_VERSION="18.0.0"
version_ge() {
  printf '%s\n%s' "$1" "$2" | sort -V | head -n1 | grep -qx "$2"
}

STEP "Vérification de Node.js"
if command -v node &>/dev/null; then
  CURRENT_NODE_VERSION="$(node -v | sed 's/^v//')"
  if version_ge "$CURRENT_NODE_VERSION" "$NODE_MIN_VERSION"; then
    LOG "Node.js v${CURRENT_NODE_VERSION} (≥ ${NODE_MIN_VERSION}) déjà installé"
  else
    LOG "Node.js v${CURRENT_NODE_VERSION} < ${NODE_MIN_VERSION}, installation via NVM"
    nvm install 18 --no-progress
    nvm alias default 18
    LOG "Node.js v$(node -v) installé"
  fi
else
  LOG "Installation de Node.js ${NODE_MIN_VERSION} via NVM"
  nvm install 18 --no-progress
  nvm alias default 18
  LOG "Node.js v$(node -v) installé"
fi
LOG "Versions actuelles : node $(node -v), npm $(npm -v)"

### 5. Définir le nom du projet ###
echo "Veuillez entrer le nom du projet :"
read -r PROJECT_NAME

# Vérifier si le nom du projet est vide et utiliser un nom par défaut si nécessaire
if [ -z "$PROJECT_NAME" ]; then
  DEFAULT_NAME="next-app-$(date +%Y%m%d%H%M%S)"
  PROJECT_NAME="$DEFAULT_NAME"
  LOG "Aucun nom de projet fourni. Utilisation du nom par défaut : ${PROJECT_NAME}"
else
  LOG "Nom de projet défini : ${PROJECT_NAME}"
fi

### 6. Préparer le dossier ~/opt/<nom_du_projet> ###
STEP "Préparation du dossier de projet"
BASE_DIR="$HOME/opt"
PROJECT_DIR="$BASE_DIR/$PROJECT_NAME"

if [ ! -d "$BASE_DIR" ]; then
  LOG "Création du dossier ${BASE_DIR}"
  mkdir -p "$BASE_DIR"
  LOG "${BASE_DIR} créé"
fi

if [ -d "$PROJECT_DIR" ]; then
  LOG "Le dossier '$PROJECT_DIR' existe déjà"
  cd "$PROJECT_DIR"
  if [ -f "package.json" ]; then
    LOG "Projet Next.js existant détecté (package.json trouvé)"
    STEP "Mise à jour des dépendances npm"
    npm install --silent
    LOG "Dépendances mises à jour"
    STEP "Vérification/installation de Prettier + ESLint"
    if ! grep -q '"prettier"' package.json; then
      LOG "Installation de Prettier + plugins ESLint"
      npm install --save-dev prettier eslint-config-prettier eslint-plugin-react eslint-plugin-react-hooks --silent
      LOG "Prettier & ESLint installés"
    else
      LOG "Prettier/ESLint déjà présents"
    fi
    if [ -d ".git" ]; then
      LOG "Dépôt Git déjà initialisé"
    else
      LOG "Initialisation d’un dépôt Git local"
      git init
      git add .
      git commit -m "Initial commit : projet existant mis à jour" > /dev/null
      LOG "Git initialisé et commit créé"
    fi
    echo
    LOG "✅ Mise à jour du projet '${PROJECT_NAME}' réussie"
    LOG "Pour lancer le serveur de dev : cd ~/opt/${PROJECT_NAME} && npm run dev"
    exit 0
  else
    ERROR "Le dossier existe mais ne contient pas de package.json"
    LOG "Suppression du dossier existant"
    rm -rf "$PROJECT_DIR"
    LOG "Dossier supprimé"
  fi
fi

### 7. Création du projet Next.js en TypeScript + ESLint ###
STEP "Création d’un nouveau projet Next.js"
cd "$BASE_DIR"
LOG "Exécution de npx create-next-app@latest ${PROJECT_NAME} --typescript --eslint --no-install"
npx create-next-app@latest "$PROJECT_NAME" --typescript --eslint --no-install > /dev/null
LOG "Squelette Next.js généré"

cd "$PROJECT_DIR"

STEP "Installation des dépendances npm"
npm install --silent
LOG "Dépendances npm installées"

### 8. Installation de Prettier + plugins ESLint ###
STEP "Vérification/installation de Prettier + ESLint"
if ! grep -q '"prettier"' package.json; then
  LOG "Installation de Prettier + plugins ESLint"
  npm install --save-dev prettier eslint-config-prettier eslint-plugin-react eslint-plugin-react-hooks --silent
  LOG "Prettier & ESLint installés"
else
  LOG "Prettier/ESLint déjà présents"
fi

### 9. Initialisation du dépôt Git local ###
STEP "Initialisation du dépôt Git"
if [ -d ".git" ]; then
  LOG "Git déjà initialisé par create-next-app"
else
  LOG "Exécution de git init"
  git init
  LOG "Git initialisé"
fi

git add .
git commit -m "Initial commit : setup Next.js (TypeScript + ESLint)" > /dev/null
LOG "Premier commit créé"

### 10. Instructions finales ###
STEP "Installation terminée"
echo
echo -e "${GREEN}${BOLD}✅ Projet Next.js '${PROJECT_NAME}' configuré avec succès dans ~/opt !${RESET}"
echo -e "${CYAN}   Pour lancer le serveur de développement :${RESET}"
echo -e "       ${BOLD}cd ~/opt/${PROJECT_NAME} && npm run dev${RESET}"
echo
echo -e "${MAGENTA}   Vous pouvez maintenant :${RESET}"
echo -e "   - Ajouter un remote : ${BOLD}git remote add origin <votre-repo-URL>${RESET}"
echo -e "   - Pousser votre premier commit : ${BOLD}git push -u origin main${RESET}"
echo
echo -e "${CYAN}   Bon coding !${RESET}"
