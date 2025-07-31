#!/bin/bash

# Demander le nom du groupe
read -p "Entrez le nom du groupe : " groupname

# Vérifier si le groupe existe déjà
if sudo getent group "$groupname" >/dev/null; then
    echo "Le groupe $groupname existe déjà."
else
    # Créer le groupe
    if sudo groupadd "$groupname"; then
        echo "Le groupe $groupname a été créé avec succès."
    else
        echo "Erreur lors de la création du groupe $groupname." >&2
        exit 1
    fi
fi

# Configurer les permissions sur le répertoire /opt/
if [ -d "/opt/" ]; then
    sudo chown -R root:"$groupname" /opt/
    sudo chmod -R 775 /opt/
    sudo setfacl -R -d -m g:"$groupname":rwx /opt/
    echo "Les permissions ont été configurées sur /opt/ pour le groupe $groupname."
else
    echo "Le répertoire /opt/ n'existe pas." >&2
    exit 1
fi

# Ajouter l'utilisateur actuel au groupe
current_user=$(whoami)
if sudo usermod -aG "$groupname" "$current_user"; then
    echo "L'utilisateur $current_user a été ajouté au groupe $groupname."
else
    echo "Erreur lors de l'ajout de l'utilisateur $current_user au groupe $groupname." >&2
    exit 1
fi

echo "Configuration terminée avec succès."
