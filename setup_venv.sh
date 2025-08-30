#!/bin/bash

# Nom de l'environnement virtuel
VENV_NAME="my_python_env"

# Créer l'environnement virtuel
python3 -m venv $VENV_NAME

# Activer l'environnement virtuel
source $VENV_NAME/bin/activate

# Mettre à jour pip
pip install --upgrade pip

# Installer telnetlib (inclus dans la bibliothèque standard, pas besoin de l'installer)
# Installer les outils de tests
pip install pytest unittest2 coverage

# Message de confirmation
echo "L'environnement virtuel '$VENV_NAME' a été créé et configuré avec les outils de tests."
echo "Pour activer l'environnement, utilisez la commande : source $VENV_NAME/bin/activate"
echo "Pour désactiver l'environnement, utilisez la commande : deactivate"
