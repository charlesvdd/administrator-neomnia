#!/usr/bin/env bash
set -e

# ----------------------------------------------------
#  Script : install.sh
#  Objectif : Préparer (ou mettre à jour) un environnement
#             React + Next.js dans /opt/<nom_du_projet>,
#             sur Debian/Ubuntu, en auto-élévation root
# ----------------------------------------------------

### 1. Auto-élévation en root si nécessaire ###
if [ "$EUID" -ne 0 ]; then
  echo "⚠️  Vous n’êtes pas root. Relance automatique avec sudo..."
  exec sudo bash "$0" "$@"
fi

### 2. Définitions des couleurs ANSI ###
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
RESET='\033[0m'

### 3. Affichage d’une bannière ASCII ###
echo -e "${CYAN}${BOLD}"
cat << "EOF"
 _   _            _   _      _       _        
| \ | | ___  __ _| \ | | ___| |_ ___| |__ ___ 
|  \| |/ _ \/ _` |  \| |/ _ \ __/ __| '_ \ __|
| |\  |  __/ (_| | |\  |  __/ || (__| | | \__ \
|_| \_|\___|\__, |_| \_|\___|\__\___|_| |_|___/
             |___/                             

   🚀   Configuration Next.js sous /opt   🚀
EOF
echo -e "${RESET}"
sleep 1  # Pause pour laisser le temps de lire la bannière

### 4. Variables globales ###
NODE_MIN_VERSION="18.0.0"
INSTALL_ESLINT_PRETTIER=true

### 5. Fonction pour comparer deux versions (via dpkg) ###
version_ge() {
  # Renvoie vrai si $1 >= $2
  dpkg --compare-versions "$1" ge "$2"
}

### 6. Mise à jour des paquets système ###
echo -e "${BLUE}➜ Mise à jour des paquets système...${RESET}"
apt-get update -y > /dev/null
apt-get upgrade -y > /dev/null
echo -e "${GREEN}✔️  Système à jour.${RESET}"

### 7. Installer Git, curl et build-essential si manquant ###
for pkg in git curl build-essential; do
  if ! dpkg -s "$pkg" &>/dev/null; then
    echo -e "${YELLOW}➜ Installation de ${pkg}...${RESET}"
    apt-get install -y "$pkg" > /dev/null
    echo -e "${GREEN}   • ${pkg} installé.${RESET}"
  else
    echo -e "${GREEN}→ ${pkg} déjà présent.${RESET}"
  fi
done

### 8. Installation / mise à jour de Node.js ≥ 18.x ###
if command -v node &>/dev/null; then
  CURRENT_NODE_VERSION="$(node -v | sed 's/^v//')"
  if version_ge "$CURRENT_NODE_VERSION" "$NODE_MIN_VERSION"; then
    echo -e "${GREEN}→ Node.js v${CURRENT_NODE_VERSION} (≥ ${NODE_MIN_VERSION}) déjà installé.${RESET}"
  else
    echo -e "${YELLOW}⚠️ Node.js v${CURRENT_NODE_VERSION} < ${NODE_MIN_VERSION} : mise à niveau...${RESET}"
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - > /dev/null 2>&1
    apt-get install -y nodejs > /dev/null
    echo -e "${GREEN}   • Node.js mis à jour vers v$(node -v | sed 's/^v//').${RESET}"
  fi
else
  echo -e "${BLUE}➜ Installation de Node.js ${NODE_MIN_VERSION}...${RESET}"
  curl -fsSL https://deb.nodesource.com/setup_18.x | bash - > /dev/null 2>&1
  apt-get install -y nodejs > /dev/null
  echo -e "${GREEN}   • Node.js v$(node -v | sed 's/^v//') installé.${RESET}"
fi

echo -e "${CYAN}→ Node.js version : $(node -v)${RESET}"
echo -e "${CYAN}→ npm version    : $(npm -v)${RESET}"

### 9. Demander le nom du projet ###
echo -ne "${MAGENTA}➜ Entrez le nom de votre projet (sans espaces, ex : mon-projet) : ${RESET}"
read -r PROJECT_NAME

if [ -z "$PROJECT_NAME" ]; then
  echo -e "${RED}❗ Erreur : nom de projet non valide.${RESET}" >&2
  exit 1
fi

### 10. Définir le chemin final dans /opt ###
PROJECT_DIR="/opt/${PROJECT_NAME}"

### 11. Si /opt n’existe pas, le créer ###
if [ ! -d "/opt" ]; then
  echo -e "${BLUE}➜ Création du dossier /opt...${RESET}"
  mkdir -p /opt
  echo -e "${GREEN}   • /opt créé.${RESET}"
fi

### 12. Si le dossier du projet existe déjà ###
if [ -d "${PROJECT_DIR}" ]; then
  echo -e "${YELLOW}⚠️ Le répertoire '${PROJECT_DIR}' existe déjà.${RESET}"
  cd "${PROJECT_DIR}"

  # Si package.json existe, on considère que c’est un projet Node existant
  if [ -f "package.json" ]; then
    echo -e "${GREEN}→ Projet existant détecté (package.json trouvé).${RESET}"
    echo -e "${BLUE}   - Mise à jour des dépendances npm...${RESET}"
    npm install > /dev/null
    echo -e "${GREEN}   • Dépendances mises à jour.${RESET}"

    echo -e "${BLUE}   - Vérification/installation de ESLint + Prettier...${RESET}"
    if [ "$INSTALL_ESLINT_PRETTIER" = true ]; then
      if ! grep -q '"prettier"' package.json; then
        echo -e "${YELLOW}     • Installation de Prettier + plugins ESLint...${RESET}"
        npm install --save-dev prettier eslint-config-prettier eslint-plugin-react eslint-plugin-react-hooks > /dev/null
        echo -e "${GREEN}       ✓ Prettier & ESLint installés.${RESET}"
      else
        echo -e "${GREEN}     • Prettier/ESLint déjà présents.${RESET}"
      fi
    fi

    # Vérifier ou initialiser Git
    if [ -d ".git" ]; then
      echo -e "${GREEN}   • Un dépôt Git est déjà initialisé ici. Vous pouvez 'git pull' si besoin.${RESET}"
    else
      echo -e "${BLUE}   - Initialisation d’un dépôt Git local...${RESET}"
      git init > /dev/null
      git add .
      git commit -m "Initial commit : projet existant mis à jour" > /dev/null
      echo -e "${GREEN}     ✓ Git initialisé & commit créé.${RESET}"
    fi

    echo
    echo -e "${GREEN}${BOLD}✅ Projet '${PROJECT_NAME}' mis à jour avec succès.${RESET}"
    echo -e "${CYAN}   Pour lancer le serveur de développement :${RESET}"
    echo -e "       ${BOLD}npm run dev${RESET}"
    exit 0

  else
    echo -e "${RED}❗ Le dossier existe mais aucun package.json (pas un projet Node valide).${RESET}"
    echo -ne "${YELLOW}❓ Voulez-vous supprimer/réinitialiser ce dossier ? (o/N) : ${RESET}"
    read -r RESP
    if [[ "$RESP" =~ ^[oO]$ ]]; then
      echo -e "${BLUE}→ Suppression de '${PROJECT_DIR}'...${RESET}"
      cd /opt
      rm -rf "${PROJECT_NAME}"
      echo -e "${GREEN}   • Dossier supprimé. Création d’un nouveau projet...${RESET}"
    else
      echo -e "${RED}❌ Abandon : dossier non réinitialisé.${RESET}"
      exit 1
    fi
  fi
fi

### 13. Création d’un nouveau projet Next.js dans /opt/<nom_du_projet> ###
echo -e "${BLUE}➜ Création du projet Next.js dans '${PROJECT_DIR}'...${RESET}"
cd /opt
npx create-next-app@latest "${PROJECT_NAME}" --typescript --eslint > /dev/null
echo -e "${GREEN}   • Projet généré par create-next-app.${RESET}"

cd "${PROJECT_DIR}"

### 14. Installation de ESLint + Prettier si manquant ###
if [ "$INSTALL_ESLINT_PRETTIER" = true ]; then
  if ! grep -q '"prettier"' package.json; then
    echo -e "${BLUE}➜ Installation de Prettier + plugins ESLint...${RESET}"
    npm install --save-dev prettier eslint-config-prettier eslint-plugin-react eslint-plugin-react-hooks > /dev/null
    echo -e "${GREEN}   • Prettier & ESLint installés.${RESET}"
  else
    echo -e "${GREEN}→ Prettier/ESLint déjà présents dans les dépendances.${RESET}"
  fi
fi

### 15. Initialisation d’un dépôt Git local ###
if [ -d ".git" ]; then
  echo -e "${GREEN}→ Git déjà initialisé par create-next-app.${RESET}"
else
  echo -e "${BLUE}➜ Initialisation d’un dépôt Git local...${RESET}"
  git init > /dev/null
  echo -e "${GREEN}   • Git initialisé.${RESET}"
fi

git add .
git commit -m "Initial commit : setup Next.js under /opt/${PROJECT_NAME}" > /dev/null
echo -e "${GREEN}   • Premier commit effectué.${RESET}"

### 16. Instructions finales ###
echo
echo -e "${GREEN}${BOLD}✅ Projet Next.js '${PROJECT_NAME}' configuré avec succès sous /opt !${RESET}"
echo -e "${CYAN}   Pour lancer le serveur de développement :${RESET}"
echo -e "       ${BOLD}cd /opt/${PROJECT_NAME}${RESET}"
echo -e "       ${BOLD}npm run dev${RESET}"
echo
echo -e "${MAGENTA}   Vous pouvez maintenant :${RESET}"
echo -e "   - Ajouter un remote : ${BOLD}git remote add origin <votre-repo-URL>${RESET}"
echo -e "   - Pousser votre premier commit : ${BOLD}git push -u origin main${RESET}"
echo
echo -e "${CYAN}   Bon coding !${RESET}"
