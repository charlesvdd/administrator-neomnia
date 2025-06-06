# Kickstarter : Site Web Apache + Serveur SQL

Ce **kickstarter** automatise l’installation d’un serveur Apache couplé à une base de données MySQL/MariaDB sur un VPS Debian/Ubuntu.  
Il inclut :
- Un script `install.sh` pour dérouler chaque étape.
- Un diagramme Mermaid détaillant l’avancée, les points de contrôle et la gestion des erreurs.
- Un exemple de configuration Apache et un script SQL pour créer la base utilisateur.
- Licence : MIT (voir [LICENSE](./LICENSE)).

---

## Diagramme d’installation

```mermaid
flowchart TD
    A[Début du script] --> B[Vérifier les privilèges root]
    B -- Pas root --> Bx([Afficher "Exécutez en root" et quitter]) 
    B -- Root OK --> C[Mettre à jour le système<br/>(apt update && apt upgrade)]
    C --> D[Installer Apache<br/>(apt install apache2 -y)]
    D --> E{Apache installé ?}
    E -- Oui --> F[Démarrer et activer Apache<br/>(systemctl enable & start apache2)]
    E -- Non --> Ex([Afficher "Erreur Apache" et quitter])
    F --> G[Installer MySQL/MariaDB<br/>(apt install mariadb-server -y)]
    G --> H{SQL installé ?}
    H -- Oui --> I[Démarrer et sécuriser SQL<br/>(mysql_secure_installation)]
    H -- Non --> Hx([Afficher "Erreur SQL" et quitter])
    I --> J[Importer script SQL<br/>(mysql < create_database.sql)]
    J --> K[Déployer configuration Apache<br/>(copier 000-default.conf)]
    K --> L{Configuration valide ?}
    L -- Oui --> M[Recharger Apache<br/>(systemctl reload apache2)]
    L -- Non --> Lx([Afficher "Erreur config Apache" et quitter])
    M --> N[Fin avec succès]
