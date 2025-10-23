#!/usr/bin/env bash
set -euo pipefail
# -------------------------------------------------------------------
#  update-neomia.sh — Outil de mise à jour pour environnements Next.js/React
#  🏢 Neomia Studio — Maintenance & Optimisation d'Environnements
#  📜 Licence : Propriétaire — Charles Van den driessche (2025)
#  Objectif : Mettre à jour Node.js, npm, Next.js, React et dépendances.
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
CHECK="${GREEN}✓${RESET}"
CROSS="${RED}✗${RESET}"
INFO="${BLUE}ℹ${RESET}"

### 2. Fonctions utilitaires ###
# Barre de progression
progress_bar() {
    local duration=${1}
    local columns=$(tput cols)
    local space=$((columns - 8))
    local bar_size=$((space - 4))
    local elapsed=0
    while [ $elapsed -lt $duration ]; do
        local filled=$((elapsed * bar_size / duration))
        printf "\r${NEOMIA} ["
        printf "%${filled}s" | tr ' ' '='
        printf "%$((bar_size - filled))s" | tr ' ' ' '
        printf "] %3d%%%%" $((elapsed * 100 / duration))
        sleep 0.1
        elapsed=$((elapsed + 1))
    done
    printf "\r${NEOMIA} ["
    printf "%${bar_size}s" | tr ' ' '='
    printf "] 100%%%%\n"
}

# Vérifier si un projet Next.js/React est présent
is_nextjs_project() {
    [ -f "package.json" ] && grep -q "\"next\"" package.json
}

is_react_project() {
    [ -f "package.json" ] && grep -q "\"react\"" package.json
}

# Récupérer la dernière version stable d'un package npm
get_latest_version() {
    local package=$1
    npm show "$package" version 2>/dev/null || echo "inconnu"
}

# Sauvegarder le projet
backup_project() {
    local backup_dir="neomia_backup_$(date +%Y%m%d_%H%M%S)"
    echo -e "${NEOMIA} ${DIM}→ Sauvegarde en cours ($backup_dir)...${RESET}"
    mkdir -p "../$backup_dir"
    cp -r . "../$backup_dir" >/dev/null 2>&1
    echo -e "${GREEN}   • ${NEOMIA} Sauvegarde créée : ../$backup_dir${RESET}"
}

### 3. Détecter les versions actuelles ###
detect_versions() {
    echo -e "${NEOMIA} ${BOLD}Analyse de l'environnement...${RESET}"

    # Node.js & npm
    NODE_CURRENT=$(node -v 2>/dev/null | sed 's/v//' || echo "non installé")
    NPM_CURRENT=$(npm -v 2>/dev/null || echo "non installé")

    # Projet
    if [ -f "package.json" ]; then
        NEXT_CURRENT=$(grep "\"next\"" package.json | awk -F: '{print $2}' | sed 's/[", ]//g' 2>/dev/null || echo "non installé")
        REACT_CURRENT=$(grep "\"react\"" package.json | awk -F: '{print $2}' | sed 's/[", ]//g' 2>/dev/null || echo "non installé")
        PROJECT_DIR=$(pwd)
        PROJECT_NAME=$(basename "$PROJECT_DIR")
    else
        echo -e "${RED}❗ ${NEOMIA} Aucun projet détecté (package.json manquant).${RESET}"
        exit 1
    fi

    # Dernières versions stables (à mettre à jour manuellement si besoin)
    NODE_LATEST=$(get_latest_version "node")
    NPM_LATEST=$(get_latest_version "npm")
    NEXT_LATEST=$(get_latest_version "next")
    REACT_LATEST=$(get_latest_version "react")

    # Affichage
    echo -e "
${NEOMIA} ${BOLD}Rapport des versions actuelles :${RESET}
---------------------------------------------------
${INFO} ${DIM}Système :${RESET}
   • Node.js    : $NODE_CURRENT (dernière: $NODE_LATEST)
   • npm        : $NPM_CURRENT (dernière: $NPM_LATEST)
${INFO} ${DIM}Projet $PROJECT_NAME :${RESET}
   • Next.js    : $NEXT_CURRENT (dernière: $NEXT_LATEST)
   • React      : $REACT_CURRENT (dernière: $REACT_LATEST)
---------------------------------------------------
"
}

### 4. Proposer les mises à jour ###
propose_updates() {
    local updates_available=0

    # Node.js
    if [ "$NODE_CURRENT" != "$NODE_LATEST" ] && [ "$NODE_CURRENT" != "non installé" ]; then
        echo -e "${YELLOW}⚠️  ${NEOMIA} Node.js $NODE_CURRENT → $NODE_LATEST${RESET}"
        updates_available=$((updates_available + 1))
    fi

    # npm
    if [ "$NPM_CURRENT" != "$NPM_LATEST" ]; then
        echo -e "${YELLOW}⚠️  ${NEOMIA} npm $NPM_CURRENT → $NPM_LATEST${RESET}"
        updates_available=$((updates_available + 1))
    fi

    # Next.js
    if [ "$NEXT_CURRENT" != "$NEXT_LATEST" ] && [ "$NEXT_CURRENT" != "non installé" ]; then
        echo -e "${YELLOW}⚠️  ${NEOMIA} Next.js $NEXT_CURRENT → $NEXT_LATEST${RESET}"
        updates_available=$((updates_available + 1))
    fi

    # React
    if [ "$REACT_CURRENT" != "$REACT_LATEST" ]; then
        echo -e "${YELLOW}⚠️  ${NEOMIA} React $REACT_CURRENT → $REACT_LATEST${RESET}"
        updates_available=$((updates_available + 1))
    fi

    # Dépendances mineures
    if [ -f "package.json" ]; then
        local outdated=$(npm outdated --parseable | wc -l)
        if [ "$outdated" -gt 0 ]; then
            echo -e "${YELLOW}⚠️  ${NEOMIA} $outdated dépendances obsolètes (voir 'npm outdated')${RESET}"
            updates_available=$((updates_available + 1))
        fi
    fi

    if [ "$updates_available" -eq 0 ]; then
        echo -e "${GREEN}${CHECK} ${NEOMIA} Tout est à jour !${RESET}"
        exit 0
    fi

    # Demander confirmation
    echo -ne "${NEOMIA} ${BOLD}Voulez-vous mettre à jour ? (o/O pour tout, n/N pour annuler, m/M pour menu) : ${RESET}"
    read -r choice
    case "$choice" in
        o|O) update_all ;;
        m|M) update_menu ;;
        *) echo -e "${RED}❌ ${NEOMIA} Annulé.${RESET}"; exit 0 ;;
    esac
}

### 5. Mise à jour complète ###
update_all() {
    backup_project
    echo -e "${NEOMIA} ${BOLD}Démarrage des mises à jour...${RESET}"

    # Node.js (via nvm)
    if [ "$NODE_CURRENT" != "$NODE_LATEST" ]; then
        echo -e "${NEOMIA} ${DIM}→ Mise à jour de Node.js...${RESET}"
        nvm install "$NODE_LATEST" --no-progress >/dev/null 2>&1 &
        progress_bar 15
        nvm alias default "$NODE_LATEST"
        echo -e "${GREEN}   • ${NEOMIA} Node.js mis à jour : $(node -v)${RESET}"
    fi

    # npm
    if [ "$NPM_CURRENT" != "$NPM_LATEST" ]; then
        echo -e "${NEOMIA} ${DIM}→ Mise à jour de npm...${RESET}"
        npm install -g npm@"$NPM_LATEST" >/dev/null 2>&1 &
        progress_bar 5
        echo -e "${GREEN}   • ${NEOMIA} npm mis à jour : $(npm -v)${RESET}"
    fi

    # Next.js & React
    if [ -f "package.json" ]; then
        echo -e "${NEOMIA} ${DIM}→ Mise à jour de Next.js et React...${RESET}"
        npm install next@"$NEXT_LATEST" react@"$REACT_LATEST" --legacy-peer-deps >/dev/null 2>&1 &
        progress_bar 20
        echo -e "${GREEN}   • ${NEOMIA} Next.js/React mis à jour.${RESET}"
    fi

    # Dépendances
    echo -e "${NEOMIA} ${DIM}→ Mise à jour des dépendances...${RESET}"
    npm update --legacy-peer-deps >/dev/null 2>&1 &
    progress_bar 30
    echo -e "${GREEN}   • ${NEOMIA} Dépendances mises à jour.${RESET}"

    # Nettoyage
    echo -e "${NEOMIA} ${DIM}→ Nettoyage du cache...${RESET}"
    npm cache clean --force >/dev/null 2>&1
    progress_bar 5

    # Rapport final
    echo -e "\n${NEOMIA} ${BOLD}Rapport de mise à jour :${RESET}"
    echo -e "---------------------------------------------------"
    echo -e "${GREEN}${CHECK} Node.js    : $(node -v)${RESET}"
    echo -e "${GREEN}${CHECK} npm        : $(npm -v)${RESET}"
    echo -e "${GREEN}${CHECK} Next.js    : $(grep "\"next\"" package.json | awk -F: '{print $2}' | sed 's/[", ]//g')${RESET}"
    echo -e "${GREEN}${CHECK} React      : $(grep "\"react\"" package.json | awk -F: '{print $2}' | sed 's/[", ]//g')${RESET}"
    echo -e "---------------------------------------------------"
    echo -e "${GREEN}✅ ${NEOMIA} Mise à jour terminée !${RESET}"
    echo -e "${CYAN}   • Redémarrez votre serveur pour appliquer les changements.${RESET}"
    echo -e "${CYAN}   • Sauvegarde disponible : ../neomia_backup_*${RESET}"
}

### 6. Menu interactif ###
update_menu() {
    while true; do
        echo -e "\n${NEOMIA} ${BOLD}Menu de mise à jour :${RESET}"
        echo -e "  1. Mettre à jour Node.js ($NODE_CURRENT → $NODE_LATEST)"
        echo -e "  2. Mettre à jour npm ($NPM_CURRENT → $NPM_LATEST)"
        echo -e "  3. Mettre à jour Next.js ($NEXT_CURRENT → $NEXT_LATEST)"
        echo -e "  4. Mettre à jour React ($REACT_CURRENT → $REACT_LATEST)"
        echo -e "  5. Mettre à jour toutes les dépendances"
        echo -e "  6. Tout mettre à jour"
        echo -e "  0. Quitter"
        echo -ne "${NEOMIA} ${BOLD}Votre choix : ${RESET}"
        read -r menu_choice
        case "$menu_choice" in
            1) nvm install "$NODE_LATEST"; nvm alias default "$NODE_LATEST" ;;
            2) npm install -g npm@"$NPM_LATEST" ;;
            3) npm install next@"$NEXT_LATEST" --legacy-peer-deps ;;
            4) npm install react@"$REACT_LATEST" --legacy-peer-deps ;;
            5) npm update --legacy-peer-deps ;;
            6) update_all; break ;;
            0) exit 0 ;;
            *) echo -e "${RED}❗ ${NEOMIA} Choix invalide.${RESET}" ;;
        esac
    done
}

### 7. Vérifications initiales ###
# Vérifier NVM
if ! command -v nvm &>/dev/null; then
    echo -e "${RED}❗ ${NEOMIA} NVM est requis pour mettre à jour Node.js.${RESET}"
    echo -e "${BLUE}➜ Installation de NVM...${RESET}"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
fi

# Vérifier npm
if ! command -v npm &>/dev/null; then
    echo -e "${RED}❗ ${NEOMIA} npm est requis.${RESET}"
    exit 1
fi

### 8. Lancement ###
detect_versions
propose_updates
