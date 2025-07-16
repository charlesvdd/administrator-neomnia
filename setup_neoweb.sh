#!/bin/bash

# Demander le nom du groupe
read -p "Entrez le nom du groupe : " groupname

# Créer le groupe
sudo groupadd $groupname

# Créer l'utilisateur Neoweb et l'ajouter au groupe
sudo useradd -m -g $groupname Neoweb

# Définir un mot de passe pour l'utilisateur Neoweb
sudo passwd Neoweb

# Configurer les permissions sur le répertoire /opt/
sudo chown -R :$groupname /opt/
sudo chmod -R g+rw /opt/

# Configurer les ACLs pour les nouveaux fichiers et dossiers
sudo setfacl -R -d -m g:$groupname:rw /opt/

echo "L'utilisateur Neoweb a été créé et ajouté au groupe $groupname avec les permissions configurées sur /opt/."
