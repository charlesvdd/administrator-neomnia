#!/usr/bin/env bash
set -euo pipefail

# ----------------------------------------------------
#  install-user.sh
#  Objectif : Installer Next.js + TypeScript + ESLint
#             en mode utilisateur (sans sudo), dans ~/opt/<nom_du_projet>
# ----------------------------------------------------

### 1. Définitions des couleurs (facultatif pour l’affichage) ###
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
RESET='\033[0m'

### 2. Affichage d’une bannière ###
echo -e "${CYAN}${BOLD}"
cat << "EOF"
 _   _            _   _      _       _        
| \ | | ___  __ _| \ | | ___| |_ ___| |__ ___ 
|  \| |/ _ \/ _` |  \| |/ _ \ __/ __| '_ \ __|
| |\  |  __/ (_| | |\  |  __/ || (__| | | \__ \
|_| \_|\___|\__, |_| \_|\___|\__\___|_| |_|___/
             |___/                             

   🚀  INSTALLATION NEXT.JS (EN MODE UTILISATEUR) 🚀
EOF
echo -e "${RESET}"
sleep 1

### 3. Détecter / installer NVM (Node Version Manager) ###
if [ -d "$HOME/.nvm" ] && [ -s "$HOME/.nvm/nvm.sh" ]; then
  echo -e "${GREEN}→ NVM déjà installé.${RESET}"
else
  echo -e "${BLUE}➜ Installation de NVM (Node Version Manager)...${RESET}"
  # On récupère le script officiel d’installation de nvm
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
  # Chargement immédiat de nvm dans le shell courant
  export NVM_DIR="$HOME/.nvm"
  # shellcheck source=/dev/null
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  echo -e "${GREEN}   • NVM installé avec succès.${RESET}"
fi

# S’assurer que nvm est disponible dans ce shell
export NVM_DIR="$HOME/.nvm"
# shellcheck source=/dev/null
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

### 4. Installer / mettre à jour Node.js >= 18 via NVM ###
NODE_MIN_VERSION="18.0.0"
# Si node existe déjà via nvm, on récupère sa version
if command -v node &>/dev/null; then
  CURRENT_NODE_VERSION="$(node -v | sed 's/^v//')"
  # Fonction basique pour comparer versions (string compare simple)
  version_ge() {
    # renvoie vrai si $1 >= $2 (major.minor.patch comparés lexicographiquement)
    printf '%s\n%s' "$1" "$2" | sort -V | head -n1 | grep -qx "$2"
  }
  if version_ge "$CURRENT_NODE_VERSION" "$NODE_MIN_VERSION"; then
    echo -e "${GREEN}→ Node.js v${CURRENT_NODE_VERSION} (≥ ${NODE_MIN_VERSION}) déjà présent via NVM.${RESET}"
  else
    echo -e "${YELLOW}⚠️ Node.js v${CURRENT_NODE_VERSION} < ${NODE_MIN_VERSION} : réinstallation via NVM...${RESET}"
    nvm install 18 --no-progress
    nvm alias default 18
    echo -e "${GREEN}   • Node.js v$(node -v) installé.${RESET}"
  fi
else
  echo -e "${BLUE}➜ Installation de Node.js ${NODE_MIN_VERSION} via NVM...${RESET}"
  nvm install 18 --no-progress
  nvm alias default 18
  echo -e "${GREEN}   • Node.js v$(node -v) installé.${RESET}"
fi
echo -e "${CYAN}→ node: $(node -v)${RESET}    ${CYAN}npm: $(npm -v)${RESET}"

### 5. Demander le nom du projet (interactif) ###
echo -ne "${MAGENTA}➜ Entrez le nom de votre projet (sans espaces, ex : mon-projet) : ${RESET}"
read -r PROJECT_NAME

if [ -z "$PROJECT_NAME" ]; then
  echo -e "${RED}❗ Erreur : vous devez fournir un nom de projet valide.${RESET}"
  exit 1
fi

### 6. Préparer le dossier ~/opt/<nom_du_projet> ###
BASE_DIR="$HOME/opt"
PROJECT_DIR="$BASE_DIR/$PROJECT_NAME"

# Créer ~/opt si nécessaire
if [ ! -d "$BASE_DIR" ]; then
  echo -e "${BLUE}➜ Création du dossier ${BASE_DIR}...${RESET}"
  mkdir -p "$BASE_DIR"
  echo -e "${GREEN}   • $BASE_DIR créé.${RESET}"
fi

# Si le projet existe déjà :
if [ -d "$PROJECT_DIR" ]; then
  echo -e "${YELLOW}⚠️ Le dossier '$PROJECT_DIR' existe déjà.${RESET}"
  cd "$PROJECT_DIR"

  # Si package.json existe, on met à jour l’existant
  if [ -f "package.json" ]; then
    echo -e "${GREEN}→ Projet Next.js existant détecté (package.json trouvé).${RESET}"
    echo -e "${BLUE}   - Mise à jour des dépendances npm...${RESET}"
    npm install --silent
    echo -e "${GREEN}   • Dépendances mises à jour.${RESET}"

    if [ "$INSTALL_ESLINT_PRETTIER" = true ]; then
      if ! grep -q '"prettier"' package.json; then
        echo -e "${BLUE}   - Installation de Prettier + plugins ESLint...${RESET}"
        npm install --save-dev prettier eslint-config-prettier eslint-plugin-react eslint-plugin-react-hooks --silent
        echo -e "${GREEN}   • Prettier & ESLint installés.${RESET}"
      else
        echo -e "${GREEN}   • Prettier/ESLint déjà présents.${RESET}"
      fi
    fi

    if [ -d ".git" ]; then
      echo -e "${GREEN}   • Dépôt Git existant détecté. Vous pouvez faire 'git pull'.${RESET}"
    else
      echo -e "${BLUE}   - Initialisation d’un dépôt Git local...${RESET}"
      git init
      git add .
      git commit -m "Initial commit : projet existant mis à jour" > /dev/null
      echo -e "${GREEN}   • Git initialisé et premier commit créé.${RESET}"
    fi

    echo
    echo -e "${GREEN}${BOLD}✅ Mise à jour du projet '$PROJECT_NAME' réussie.${RESET}"
    echo -e "${CYAN}   Pour lancer le serveur de dev : cd ~/opt/$PROJECT_NAME && npm run dev${RESET}"
    exit 0
  fi

  # Si pas de package.json, on propose de réinitialiser
  echo -e "${RED}❗ Le dossier existe mais ne contient pas de package.json (pas un projet valide).${RESET}"
  echo -ne "${YELLOW}❓ Voulez-vous supprimer et recréer ce dossier ? (o/N) : ${RESET}"
  read -r RESP
  if [[ "$RESP" =~ ^[oO]$ ]]; then
    echo -e "${BLUE}➜ Suppression de '$PROJECT_DIR'...${RESET}"
    rm -rf "$PROJECT_DIR"
    echo -e "${GREEN}   • Dossier supprimé.${RESET}"
  else
    echo -e "${RED}❌ Abandon. Le dossier n’a pas été modifié.${RESET}"
    exit 1
  fi
fi

### 7. Création du projet Next.js en TypeScript + ESLint ###
echo -e "${BLUE}➜ Création du projet Next.js dans '$PROJECT_DIR'...${RESET}"
cd "$BASE_DIR"
npx create-next-app@latest "$PROJECT_NAME" --typescript --eslint --no-install > /dev/null
echo -e "${GREEN}   • Squelette Next.js généré.${RESET}"

cd "$PROJECT_DIR"

# Installer toutes les dépendances générées
echo -e "${BLUE}➜ Installation des dépendances npm...${RESET}"
npm install --silent
echo -e "${GREEN}   • Dépendances npm installées.${RESET}"

### 8. Installer Prettier + plugins ESLint si absent ###
if [ "$INSTALL_ESLINT_PRETTIER" = true ]; then
  if ! grep -q '"prettier"' package.json; then
    echo -e "${BLUE}➜ Installation de Prettier + plugins ESLint...${RESET}"
    npm install --save-dev prettier eslint-config-prettier eslint-plugin-react eslint-plugin-react-hooks --silent
    echo -e "${GREEN}   • Prettier & ESLint installés.${RESET}"
  else
    echo -e "${GREEN}→ Prettier/ESLint déjà présents dans package.json.${RESET}"
  fi
fi

### 9. Initialisation du dépôt Git local ###
if [ -d ".git" ]; then
  echo -e "${GREEN}→ Git déjà initialisé par create-next-app.${RESET}"
else
  echo -e "${BLUE}➜ Initialisation d’un dépôt Git local...${RESET}"
  git init
  echo -e "${GREEN}   • Git initialisé.${RESET}"
fi

git add .
git commit -m "Initial commit : setup Next.js (TypeScript + ESLint)" > /dev/null
echo -e "${GREEN}   • Premier commit créé.${RESET}"

### 10. Instructions finales ###
echo
echo -e "${GREEN}${BOLD}✅ Projet Next.js '$PROJECT_NAME' configuré avec succès dans ~/opt !${RESET}"
echo -e "${CYAN}   Pour lancer le serveur de développement :${RESET}"
echo -e "       ${BOLD}cd ~/opt/$PROJECT_NAME && npm run dev${RESET}"
echo
echo -e "${MAGENTA}   Vous pouvez maintenant :${RESET}"
echo -e "   - Ajouter un remote : ${BOLD}git remote add origin <votre-repo-URL>${RESET}"
echo -e "   - Pousser votre premier commit : ${BOLD}git push -u origin main${RESET}"
echo
echo -e "${CYAN}   Bon coding !${RESET}"
