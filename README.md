Mission
Sauvegarde des clés SSH
Versionner les fichiers de clés publiques/privées (en gardant à l'esprit la sécurité et en évitant de versionner les clés privées en clair sur un dépôt public) ainsi que le fichier authorized_keys pour les utilisateurs autorisés.

Configuration des utilisateurs
Sauvegarder et documenter les configurations des utilisateurs, les groupes, ainsi que les paramètres spécifiques définis dans /etc/passwd, /etc/group, et tout fichier de configuration personnalisé (par exemple, des scripts d’initiation des comptes utilisateurs).

Paramètres système d’Ubuntu
Conserver la configuration du service SSH (fichiers tels que /etc/ssh/sshd_config et /etc/ssh/ssh_config), et toute autre configuration système liée aux comptes utilisateurs.

Structure du dépôt
perl
Copy
HuginnProject-system-users/
├── ssh/
│   ├── sshd_config
│   ├── ssh_config
│   └── authorized_keys_example
├── users/
│   ├── users-list.txt         # Liste des utilisateurs et groupes (exportée depuis /etc/passwd, /etc/group)
│   └── setup-users.sh         # Script pour recréer ou synchroniser la configuration des utilisateurs
└── docs/
    └── system-users-guide.md  # Documentation détaillant les procédures de sauvegarde, restauration et bonnes pratiques
Bonnes pratiques
Sécurité

Évitez de versionner des clés privées sensibles dans ce dépôt, surtout s’il est public.
Utilisez des dépôts privés ou des mécanismes de chiffrement pour les données sensibles.
Automatisation

Mettez en place des scripts qui exportent régulièrement les configurations actuelles et les stockent dans ce dépôt.
Documentez la procédure de restauration en cas de besoin.
Documentation

Le fichier docs/system-users-guide.md doit détailler comment utiliser les fichiers et scripts contenus dans ce dépôt pour restaurer ou mettre à jour la configuration des utilisateurs et des clés SSH.
