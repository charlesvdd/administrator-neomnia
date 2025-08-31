#!/bin/bash

# Nom de l'environnement virtuel
VENV_NAME="mon_environnement"

# Vérifier si Python 3 est installé
if ! command -v python3 &> /dev/null; then
    echo "Python 3 n'est pas installé. Installation en cours..."
    sudo apt update
    sudo apt install -y python3 python3-pip python3-venv
fi

# Créer l'environnement virtuel
echo "Création de l'environnement virtuel '$VENV_NAME'..."
python3 -m venv $VENV_NAME

# Activer l'environnement
echo "Activation de l'environnement virtuel..."
source $VENV_NAME/bin/activate

# Mettre à jour pip
echo "Mise à jour de pip..."
pip install --upgrade pip

# Vérifier si requirements.txt existe et installer les dépendances
if [ -f "requirements.txt" ]; then
    echo "Installation des dépendances depuis requirements.txt..."
    pip install -r requirements.txt
else
    echo "Aucun fichier requirements.txt trouvé. Aucune dépendance installée."
fi

# Message de confirmation
echo "Environnement virtuel '$VENV_NAME' prêt à l'emploi !"
echo "Pour l'activer manuellement plus tard, utilisez :"
echo "source $VENV_NAME/bin/activate"

# Optionnel : Lancer une commande après l'installation
# Par exemple, exécuter un script Python ou des tests
# echo "Lancement de l'application..."
# python mon_script.py
