#!/bin/bash

# Nom du script
SCRIPT_NAME="setup_venv_improved.sh"

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # Pas de couleur

# Fonction pour afficher les logs avec le nom du script
log_info() {
    echo -e "${BLUE}[${SCRIPT_NAME}]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[${SCRIPT_NAME}]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[${SCRIPT_NAME}]${NC} $1"
}

log_error() {
    echo -e "${RED}[${SCRIPT_NAME}]${NC} $1"
}

# Nom de l'environnement virtuel
VENV_NAME="my_python_env"

# Fonction pour mettre à jour les paquets à la fin
update_packages() {
    log_info "Mise à jour des paquets installés..."
    pip list --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1 | xargs -n1 pip install -U
    log_success "Mise à jour des paquets terminée."
}

# Créer l'environnement virtuel
log_info "Création de l'environnement virtuel '$VENV_NAME'..."
python3 -m venv $VENV_NAME || {
    log_error "Échec de la création de l'environnement virtuel."
    exit 1
}

# Activer l'environnement virtuel
log_info "Activation de l'environnement virtuel..."
source $VENV_NAME/bin/activate || {
    log_error "Échec de l'activation de l'environnement virtuel."
    exit 1
}

# Mettre à jour pip
log_info "Mise à jour de pip..."
pip install --upgrade pip || {
    log_error "Échec de la mise à jour de pip."
    exit 1
}

# Installer les outils de tests
log_info "Installation des outils de tests..."
pip install pytest coverage || {
    log_error "Échec de l'installation des outils de tests."
    exit 1
}

# Message de confirmation
log_success "L'environnement virtuel '$VENV_NAME' a été créé et configuré avec les outils de tests."
log_info "Pour activer l'environnement, utilisez la commande : source $VENV_NAME/bin/activate"
log_info "Pour désactiver l'environnement, utilisez la commande : deactivate"

# Mise à jour des paquets en fin de cycle
update_packages
