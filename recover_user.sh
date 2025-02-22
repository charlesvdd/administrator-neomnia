#!/bin/bash
# Script de récupération des clés utilisateur depuis la sauvegarde Git

# Répertoire où se trouve la sauvegarde (clonage du dépôt GitHub)
BACKUP_DIR="/var/backups/git/HuginnProject-system-users"

# Répertoire de base des utilisateurs
TARGET_BASE="/home"

echo "Début de la procédure de récupération des clés utilisateurs..."

# Vérifie que le répertoire de sauvegarde existe
if [ ! -d "$BACKUP_DIR" ]; then
    echo "Erreur : Le répertoire de sauvegarde $BACKUP_DIR est introuvable."
    exit 1
fi

# Parcourt chaque dossier utilisateur présent dans la sauvegarde
for USER_DIR in "$BACKUP_DIR"/*; do
    if [ -d "$USER_DIR" ]; then
        USERNAME=$(basename "$USER_DIR")
        TARGET_USER_DIR="$TARGET_BASE/$USERNAME"
        
        echo "Récupération pour l'utilisateur : $USERNAME"
        
        # Vérifie que le répertoire /home/username existe
        if [ -d "$TARGET_USER_DIR" ]; then
            # Crée le dossier .ssh s'il n'existe pas
            if [ ! -d "$TARGET_USER_DIR/.ssh" ]; then
                mkdir "$TARGET_USER_DIR/.ssh"
                chown $USERNAME:$USERNAME "$TARGET_USER_DIR/.ssh"
                chmod 700 "$TARGET_USER_DIR/.ssh"
            fi

            # Si un dossier .ssh a été sauvegardé pour cet utilisateur, le copier
            if [ -d "$USER_DIR/.ssh" ]; then
                cp -r "$USER_DIR/.ssh/"* "$TARGET_USER_DIR/.ssh/"
                chown -R $USERNAME:$USERNAME "$TARGET_USER_DIR/.ssh"
                chmod 600 "$TARGET_USER_DIR/.ssh/"*
                echo "Clés .ssh récupérées pour $USERNAME."
            else
                echo "Aucun dossier .ssh trouvé dans la sauvegarde pour $USERNAME."
            fi
        else
            echo "Le répertoire $TARGET_USER_DIR n'existe pas. Récupération impossible pour $USERNAME."
        fi
    fi
done

echo "Procédure de récupération terminée."
