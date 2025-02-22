#!/bin/bash

# Variables
BACKUP_DIR="/var/backups"
BACKUP_FILE="backup_vps_$(date +%Y-%m-%d).tar.gz"
PACKAGE_LIST="packages.list"

echo "📦 Sauvegarde en cours..."

# Sauvegarde de la liste des paquets installés
dpkg --get-selections > "$BACKUP_DIR/$PACKAGE_LIST"

# Création de l’archive complète du VPS
tar --exclude={"/proc","/sys","/dev","/run","/tmp","/mnt","/media","/lost+found"} \
    -czvf "$BACKUP_DIR/$BACKUP_FILE" \
    /etc /var/backups /home /root /var/www /opt "$BACKUP_DIR/$PACKAGE_LIST"

echo "✅ Sauvegarde terminée : $BACKUP_DIR/$BACKUP_FILE"