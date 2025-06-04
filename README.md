# 🖥️ Installation du Script “init.ssh” via RAW GitHub

Ce README présente de manière claire et visuelle comment récupérer et exécuter, en une seule commande, le script `init.ssh` disponible sur GitHub. Le but est de préparer rapidement un serveur Ubuntu (VPS) en automatisant les tâches suivantes :

- Mise à jour du système
- Installation des paquets essentiels
- Configuration basique du pare-feu (UFW)
- Création d’un groupe “admins” et attribution des droits sur `/etc` et `/opt`
- Ajout de l’utilisateur courant au groupe “admins”

---

## 🚀 Commande d’exécution

Pour lancer le script directement depuis la branche `init` de votre dépôt GitHub, ouvrez un terminal sur votre machine (ou votre VPS) et copiez‐collez :

```bash
curl -fsSL https://raw.githubusercontent.com/charlesvdd/administrator-neomnia/init/init.ssh | sudo bash
