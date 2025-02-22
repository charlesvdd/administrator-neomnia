#!/bin/bash
set -e  # Arrête le script en cas d'erreur

USER="neoweb"
GIT_REPO="git@github.com:neoweb2212/HuginnProject-system-users.git"
INSTALL_DIR="/home/$USER"

echo "=== Mise à jour du système ==="
sudo apt update && sudo apt upgrade -y

echo "=== Création de l'utilisateur $USER ==="
sudo adduser --gecos "" --disabled-password $USER
sudo usermod -aG sudo $USER  # Ajout aux sudoers

echo "=== Configuration SSH ==="
sudo mkdir -p $INSTALL_DIR/.ssh
sudo cp $(pwd)/$USER/.ssh/authorized_keys $INSTALL_DIR/.ssh/
sudo chown -R $USER:$USER $INSTALL_DIR/.ssh
sudo chmod 700 $INSTALL_DIR/.ssh
sudo chmod 600 $INSTALL_DIR/.ssh/authorized_keys

echo "=== Copie des fichiers de configuration ==="
sudo cp -r $(pwd)/$USER/.bashrc $INSTALL_DIR/
sudo cp -r $(pwd)/$USER/.profile $INSTALL_DIR/
sudo chown -R $USER:$USER $INSTALL_DIR

echo "=== Installation et configuration du pare-feu UFW ==="
sudo apt install ufw -y
sudo ufw allow OpenSSH
sudo ufw --force enable

echo "=== Installation terminée ! L'utilisateur $USER est prêt. ==="
