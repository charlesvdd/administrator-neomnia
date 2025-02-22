#!/bin/bash

# Définition du dossier et du fichier de sauvegarde
BACKUP_DIR="/var/backups"
BACKUP_FILE="backup_vps_$(date +%Y-%m-%d).tar.gz"

# Création de la sauvegarde
echo "📦 Création de la sauvegarde : $BACKUP_FILE"
tar --exclude={"/proc","/sys","/dev","/run","/tmp","/mnt","/media","/lost+found"} \
    -czvf "$BACKUP_DIR/$BACKUP_FILE" \
    /home /etc/passwd /etc/group /etc/shadow /etc/gshadow /var/lib/dpkg /var/lib/apt /var/cache/apt

echo "✅ Sauvegarde terminée."

# Trouver le dernier fichier créé
LATEST_FILE=$(ls -t "$BACKUP_DIR" | head -n1)

# Ajouter uniquement le dernier fichier à Git
cd "$BACKUP_DIR"
git add "$LATEST_FILE"
git commit -m "Sauvegarde automatique du VPS : $LATEST_FILE"
git push origin main

echo "✅ Dernier fichier sauvegardé et poussé sur GitHub : $LATEST_FILE"
