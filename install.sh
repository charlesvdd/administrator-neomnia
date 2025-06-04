#!/usr/bin/env bash
set -e

# ----------------------------------------------------
#  Script: install.sh
#  Purpose: Prepare (or update) a React + Next.js project
#           environment on Debian/Ubuntu, running as root
# ----------------------------------------------------

### 1. Auto‐elevate to root if not already ###
if [ "$EUID" -ne 0 ]; then
  echo "⚠️  Not running as root. Re-launching with sudo..."
  exec sudo bash "$0" "$@"
fi

### 2. ANSI Color Definitions ###
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
RESET='\033[0m'

### 3. ASCII Banner ###
echo -e "${CYAN}${BOLD}"
cat << "EOF"
 _   _            _   _      _       _        
| \ | | ___  __ _| \ | | ___| |_ ___| |__ ___ 
|  \| |/ _ \/ _` |  \| |/ _ \ __/ __| '_ \ __|
| |\  |  __/ (_| | |\  |  __/ || (__| | | \__ \
|_| \_|\___|\__, |_| \_|\___|\__\___|_| |_|___/
             |___/                             

   🚀   Setup React + Next.js Environment   🚀
EOF
echo -e "${RESET}"
sleep 1  # Pause to let user see the banner

### 4. Global Variables ###
NODE_MIN_VERSION="18.0.0"
PROJECT_NAME=""
INSTALL_ESLINT_PRETTIER=true

### 5. Function: Compare Versions (using dpkg) ###
version_ge() {
  # Returns true if $1 >= $2
  dpkg --compare-versions "$1" ge "$2"
}

### 6. Update System Packages ###
echo -e "${BLUE}➜ Updating system packages...${RESET}"
apt-get update -y > /dev/null
apt-get upgrade -y > /dev/null
echo -e "${GREEN}✔️  System packages are up to date.${RESET}"

### 7. Install Git, curl, build-essential If Missing ###
for pkg in git curl build-essential; do
  if ! dpkg -s "$pkg" &>/dev/null; then
    echo -e "${YELLOW}➜ Installing ${pkg}...${RESET}"
    apt-get install -y "$pkg" > /dev/null
    echo -e "${GREEN}   • ${pkg} installed.${RESET}"
  else
    echo -e "${GREEN}→ ${pkg} already installed.${RESET}"
  fi
done

### 8. Check / Install Node.js ≥ 18.x ###
if command -v node &>/dev/null; then
  CURRENT_NODE_VERSION="$(node -v | sed 's/^v//')"
  if version_ge "$CURRENT_NODE_VERSION" "$NODE_MIN_VERSION"; then
    echo -e "${GREEN}→ Node.js v${CURRENT_NODE_VERSION} (≥ ${NODE_MIN_VERSION}) is already installed.${RESET}"
  else
    echo -e "${YELLOW}⚠️  Node.js v${CURRENT_NODE_VERSION} < ${NODE_MIN_VERSION}: upgrading...${RESET}"
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - > /dev/null 2>&1
    apt-get install -y nodejs > /dev/null
    echo -e "${GREEN}   • Node.js upgraded to v$(node -v | sed 's/^v//').${RESET}"
  fi
else
  echo -e "${BLUE}➜ Installing Node.js ${NODE_MIN_VERSION}...${RESET}"
  curl -fsSL https://deb.nodesource.com/setup_18.x | bash - > /dev/null 2>&1
  apt-get install -y nodejs > /dev/null
  echo -e "${GREEN}   • Node.js v$(node -v | sed 's/^v//') installed.${RESET}"
fi

echo -e "${CYAN}→ Node.js version: $(node -v)${RESET}"
echo -e "${CYAN}→ npm version    : $(npm -v)${RESET}"

### 9. Obtain Project Name (argument or prompt) ###
if [ -z "$1" ]; then
  echo -ne "${MAGENTA}➜ Enter project name (no spaces, e.g. my-project): ${RESET}"
  read -r PROJECT_NAME
else
  PROJECT_NAME="$1"
fi

if [ -z "$PROJECT_NAME" ]; then
  echo -e "${RED}❗ Error: You must provide a valid project name.${RESET}" >&2
  exit 1
fi

### 10. If Project Directory Already Exists ###
if [ -d "$PROJECT_NAME" ]; then
  echo -e "${YELLOW}⚠️  Directory '${PROJECT_NAME}' already exists.${RESET}"
  cd "$PROJECT_NAME"

  # If package.json exists, treat it as an existing Node project
  if [ -f "package.json" ]; then
    echo -e "${GREEN}→ Existing Node/Next.js project detected (package.json found).${RESET}"
    echo -e "${BLUE}   - Running 'npm install' to update dependencies...${RESET}"
    npm install > /dev/null
    echo -e "${GREEN}   • Dependencies updated.${RESET}"

    echo -e "${BLUE}   - Verifying/Installing ESLint + Prettier...${RESET}"
    if [ "$INSTALL_ESLINT_PRETTIER" = true ]; then
      if ! grep -q '"prettier"' package.json; then
        echo -e "${YELLOW}     • Installing Prettier + ESLint plugins...${RESET}"
        npm install --save-dev prettier eslint-config-prettier eslint-plugin-react eslint-plugin-react-hooks > /dev/null
        echo -e "${GREEN}       ✓ Prettier & ESLint installed.${RESET}"
      else
        echo -e "${GREEN}     • Prettier/ESLint already present in dependencies.${RESET}"
      fi
    fi

    # Check or initialize Git repository
    if [ -d ".git" ]; then
      echo -e "${GREEN}   • Git repository found. You may 'git pull' or continue developing.${RESET}"
    else
      echo -e "${BLUE}   - Initializing a new Git repository...${RESET}"
      git init > /dev/null
      git add .
      git commit -m "Initial commit: existing project updated" > /dev/null
      echo -e "${GREEN}     ✓ Git initialized & first commit created.${RESET}"
    fi

    echo
    echo -e "${GREEN}${BOLD}✅ Project '${PROJECT_NAME}' updated successfully.${RESET}"
    echo -e "${CYAN}   To start the development server:${RESET}"
    echo -e "       ${BOLD}npm run dev${RESET}"
    exit 0
  else
    echo -e "${RED}❗ Directory exists but no package.json found (not a valid Node project).${RESET}"
    echo -ne "${YELLOW}❓ Do you want to delete and reinitialize this directory? (y/N): ${RESET}"
    read -r RESP
    if [[ "$RESP" =~ ^[yY]$ ]]; then
      echo -e "${BLUE}→ Deleting '${PROJECT_NAME}'...${RESET}"
      cd ..
      rm -rf "$PROJECT_NAME"
      echo -e "${GREEN}   • Deleted. Proceeding to create a new project...${RESET}"
    else
      echo -e "${RED}❌ Aborting: existing directory not reinitialized.${RESET}"
      exit 1
    fi
  fi
fi

### 11. Create New Next.js Project ###
echo -e "${BLUE}➜ Creating Next.js project '${PROJECT_NAME}'...${RESET}"
npx create-next-app@latest "$PROJECT_NAME" --typescript --eslint > /dev/null
echo -e "${GREEN}   • Project scaffolded by create-next-app.${RESET}"

cd "$PROJECT_NAME"

### 12. Install ESLint + Prettier If Missing ###
if [ "$INSTALL_ESLINT_PRETTIER" = true ]; then
  if ! grep -q '"prettier"' package.json; then
    echo -e "${BLUE}➜ Installing Prettier + ESLint plugins...${RESET}"
    npm install --save-dev prettier eslint-config-prettier eslint-plugin-react eslint-plugin-react-hooks > /dev/null
    echo -e "${GREEN}   • Prettier & ESLint plugins installed.${RESET}"
  else
    echo -e "${GREEN}→ Prettier/ESLint already present in dependencies.${RESET}"
  fi
fi

### 13. Initialize or Update Git Repository ###
if [ -d ".git" ]; then
  echo -e "${GREEN}→ Git already initialized by create-next-app.${RESET}"
else
  echo -e "${BLUE}➜ Initializing a local Git repository...${RESET}"
  git init > /dev/null
  echo -e "${GREEN}   • Git initialized.${RESET}"
fi

git add .
git commit -m "Initial commit: setup initial Next.js project" > /dev/null
echo -e "${GREEN}   • First commit created.${RESET}"

### 14. Final Instructions ###
echo
echo -e "${GREEN}${BOLD}✅ Next.js project '${PROJECT_NAME}' set up successfully!${RESET}"
echo -e "${CYAN}   To start the development server:${RESET}"
echo -e "       ${BOLD}cd ${PROJECT_NAME}${RESET}"
echo -e "       ${BOLD}npm run dev${RESET}"
echo
echo -e "${MAGENTA}   You can now:${RESET}"
echo -e "   - Add a remote: ${BOLD}git remote add origin <your-repo-URL>${RESET}"
echo -e "   - Push your first commit: ${BOLD}git push -u origin main${RESET}"
echo
echo -e "${CYAN}   Happy coding!${RESET}"
