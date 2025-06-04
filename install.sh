#!/usr/bin/env bash
set -e

# ----------------------------------------------------
#  Script : setup-nextjs-graphique.sh
#  Objectif : Préparer (ou mettre à jour) l'environnement pour un
#             projet React + Next.js sur Debian/Ubuntu, avec un affichage coloré
# ----------------------------------------------------

### 1. Définitions des couleurs (ANSI)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
RESET='\033[0m'

### 2. Affichage de la bannière ASCII
echo -e "${CYAN}${BOLD}"
cat << "EOF"
 _   _            _   _      _       _        
| \ | | ___  __ _| \ | | ___| |_ ___| |__ ___ 
|  \| |/ _ \/ _` |  \| |/ _ \ __/ __| '_ \ __|
| |\  |  __/ (_| | |\  |  __/ || (__| | | \__ \
|_| \_|\___|\__, |_| \_|\___|\__\___|_| |_|___/
             |___/                             

   🚀   Setup React + Next.js environment   🚀
EOF
echo -e "${RESET}"

sleep 1  # petit délai pour laisser le temps de lire la bannière

### 3. Vérification des droits root (sudo)
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}❗ Merci d'exécuter ce script en tant que root (ou via sudo).${RESET}" >&2
  exit 1
fi

### 4. Variables globales
NODE_REQUIRED_VERSION="18.0.0"
PROJECT_NAME=""
INSTALL_ESLINT_PRETTIER=true

### 5. Fonction pour comparer deux versions (utilise dpkg pour Debian/Ubuntu)
version_ge() {
  # renvoie vrai si $1 >= $2
  dpkg --compare-versions "$1" ge "$2"
}

#### 6. Mise à jour des paquets système (toujours OK à ré-exécuter)
echo -e "${BLUE}➜ Mise à jour des paquets système...${RESET}"
apt-get update -y > /dev/null
apt-get upgrade -y > /dev/null
echo -e "${GREEN}✔️  Système à jour.${RESET}"

#### 7. Installation conditionnelle de Git, curl et build-essential
for pkg in git curl build-essential; do
  if ! dpkg -s "$pkg" &>/dev/null; then
    echo -e "${YELLOW}➜ Installation de ${pkg}...${RESET}"
    apt-get install -y "$pkg" > /dev/null
    echo -e "${GREEN}   • ${pkg} installé.${RESET}"
  else
    echo -e "${GREEN}→ ${pkg} est déjà installé.${RESET}"
  fi
done

#### 8. Vérification/install de Node.js version >= 18.x
if command -v node &>/dev/null; then
  CURRENT_NODE_VERSION="$(node -v | sed 's/^v//')"
  if version_ge "$CURRENT_NODE_VERSION" "$NODE_REQUIRED_VERSION"; then
    echo -e "${GREEN}→ Node.js v${CURRENT_NODE_VERSION} (>= ${NODE_REQUIRED_VERSION}) déjà installé.${RESET}"
  else
    echo -e "${YELLOW}⚠️  Node.js v${CURRENT_NODE_VERSION} < ${NODE_REQUIRED_VERSION} : mise à jour en cours...${RESET}"
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - > /dev/null 2>&1
    apt-get install -y nodejs > /dev/null
    echo -e "${GREEN}   • Node.js mis à jour vers v$(node -v | sed 's/^v//').${RESET}"
  fi
else
  echo -e "${BLUE}➜ Installation de Node.js ${NODE_REQUIRED_VERSION}...${RESET}"
  curl -fsSL https://deb.nodesource.com/setup_18.x | bash - > /dev/null 2>&1
  apt-get install -y nodejs > /dev/null
  echo -e "${GREEN}   • Node.js v$(node -v | sed 's/^v//') installé.${RESET}"
fi

echo -e "${CYAN}→ Node.js version : $(node -v)${RESET}"
echo -e "${CYAN}→ npm version     : $(npm -v)${RESET}"

#### 9. Nom du projet (passé en argument ou interactif)
if [ -z "$1" ]; then
  echo -ne "${MAGENTA}➜ Nom du projet Next.js (sans espaces, ex : mon-projet) : ${RESET}"
  read -r PROJECT_NAME
else
  PROJECT_NAME="$1"
fi

if [ -z "$PROJECT_NAME" ]; then
  echo -e "${RED}❗ Erreur : vous devez fournir un nom de projet valide.${RESET}" >&2
  exit 1
fi

#### 10. Si le dossier du projet existe déjà
if [ -d "$PROJECT_NAME" ]; then
  echo -e "${YELLOW}⚠️  Le dossier '${PROJECT_NAME}' existe déjà.${RESET}"
  cd "$PROJECT_NAME"

  # Si package.json existe : on considère que c'est un projet Node
  if [ -f "package.json" ]; then
    echo -e "${GREEN}→ Projet existant détecté (package.json présent).${RESET}"
    echo -e "${BLUE}   - Mise à jour des dépendances npm...${RESET}"
    npm install > /dev/null
    echo -e "${GREEN}   • Dépendances mises à jour.${RESET}"

    echo -e "${BLUE}   - Vérification/installation d'ESLint et Prettier...${RESET}"
    if [ "$INSTALL_ESLINT_PRETTIER" = true ]; then
      if ! grep -q '"prettier"' package.json; then
        echo -e "${YELLOW}     • Installation de Prettier + compléments ESLint...${RESET}"
        npm install --save-dev prettier eslint-config-prettier eslint-plugin-react eslint-plugin-react-hooks > /dev/null
        echo -e "${GREEN}       ✓ Prettier et ESLint installés.${RESET}"
      else
        echo -e "${GREEN}     • Prettier/ESLint déjà installés.${RESET}"
      fi
    fi

    # Mise à jour du dépôt Git (si initialisé)
    if [ -d ".git" ]; then
      echo -e "${GREEN}   • Dépôt Git local détecté. (git pull possible si c'est un clone)${RESET}"
    else
      echo -e "${BLUE}   - Initialisation d'un dépôt Git local...${RESET}"
      git init > /dev/null
      git add .  
      git commit -m "Initial commit : projet existant mis à jour" > /dev/null
      echo -e "${GREEN}     ✓ Git initialisé et commit créé.${RESET}"
    fi

    echo
    echo -e "${GREEN}${BOLD}✅ Mise à jour du projet '${PROJECT_NAME}' terminée.${RESET}"
    echo -e "${CYAN}   Pour lancer le serveur de développement :${RESET}"
    echo -e "       ${BOLD}npm run dev${RESET}"
    exit 0
  else
    echo -e "${RED}❗ Le dossier existe mais ne contient pas de package.json (pas de projet Node valide).${RESET}"
    echo -ne "${YELLOW}❓ Souhaitez-vous supprimer/réinitialiser ce dossier ? (o/N) : ${RESET}"
    read -r RESP
    if [[ "$RESP" =~ ^[oO]$ ]]; then
      echo -e "${BLUE}→ Suppression de '${PROJECT_NAME}' en cours...${RESET}"
      cd ..
      rm -rf "$PROJECT_NAME"
      echo -e "${GREEN}   • Dossier supprimé. Recréation du projet...${RESET}"
    else
      echo -e "${RED}❌ Interruption : le dossier existe et n'a pas été réinitialisé.${RESET}"
      exit 1
    fi
  fi
fi

#### 11. Création d'un nouveau projet Next.js
echo -e "${BLUE}➜ Création du projet Next.js '${PROJECT_NAME}'...${RESET}"
npx create-next-app@latest "$PROJECT_NAME" --typescript --eslint > /dev/null
echo -e "${GREEN}   • Projet généré par create-next-app.${RESET}"

cd "$PROJECT_NAME"

#### 12. Installation conditionnelle d'ESLint + Prettier (si non présents)
if [ "$INSTALL_ESLINT_PRETTIER" = true ]; then
  if ! grep -q '"prettier"' package.json; then
    echo -e "${BLUE}➜ Installation de Prettier + compléments ESLint...${RESET}"
    npm install --save-dev prettier eslint-config-prettier eslint-plugin-react eslint-plugin-react-hooks > /dev/null
    echo -e "${GREEN}   • Prettier et ESLint installés.${RESET}"
  else
    echo -e "${GREEN}→ Prettier/ESLint déjà présents dans les dépendances.${RESET}"
  fi
fi

#### 13. Initialisation d’un dépôt Git local
if [ -d ".git" ]; then
  echo -e "${GREEN}→ Git est déjà initialisé par create-next-app.${RESET}"
else
  echo -e "${BLUE}➜ Initialisation d'un dépôt Git local...${RESET}"
  git init > /dev/null
  echo -e "${GREEN}   • Git initialisé.${RESET}"
fi
git add .  
git commit -m "Initial commit : setup initial Next.js project" > /dev/null
echo -e "${GREEN}   • Premier commit effectué.${RESET}"

#### 14. Instructions finales
echo
echo -e "${GREEN}${BOLD}✅ Projet Next.js '${PROJECT_NAME}' configuré avec succès !${RESET}"
echo -e "${CYAN}   Pour démarrer le serveur de développement :${RESET}"
echo -e "       ${BOLD}cd ${PROJECT_NAME}${RESET}"
echo -e "       ${BOLD}npm run dev${RESET}"
echo
echo -e "${MAGENTA}   Vous pouvez également :${RESET}"
echo -e "   - Ajouter votre dépôt distant : ${BOLD}git remote add origin <URL_DU_REPO>${RESET}"
echo -e "   - Pousser la première version : ${BOLD}git push -u origin main${RESET}"
echo
echo -e "${CYAN}   Bon développement !${RESET}"
