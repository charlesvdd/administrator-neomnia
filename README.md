# NEOMNIA™ Git-Wrapper

![Git-Wrapper v1.0.0 – Secure GitOps Ready™](https://img.shields.io/badge/Git--Wrapper_v1.0.0-Secure_GitOps_Ready%E2%84%A2-blue)

> **Secure GitHub Backup & Wrapper Tool**
> Version **1.0.0** – © NEOMNIA 2025

---

## 🚀 Présentation

**NEOMNIA™ Git-Wrapper** est un script Bash élégant et sécurisé qui permet de **cloner** ou **mettre à jour** en masse vos dépôts GitHub tout en protégeant votre Personal Access Token grâce à un chiffrement AES-256. Il intègre :

* 🔒 Chiffrement du token GitHub (PAT) avec OpenSSL
* 🛡️ Authentification automatique via GitHub CLI
* 📁 Clonage OU mise à jour (`git pull`) de plusieurs dépôts
* 🧾 Journalisation pas-à-pas avec emoji et logo NEOMNIA™
* 🔐 Permissions sécurisées (770) sur le dossier de sauvegarde
* 🔢 Versioning interne (`VERSION=1.0.0`)

---

## 📦 Installation rapide

```bash
# Exécution directe depuis GitHub RAW
bash <(curl -s https://raw.githubusercontent.com/charlesvdd/administrator-neomnia/main/git-wrapper.sh) owner/repo [owner2/repo2 ...]
```

> Remplace `owner/repo` par le ou les dépôts que tu souhaites sauvegarder.

---

## 🛠️ Installation locale classique

```bash
# 1. Clone le dépôt
git clone https://github.com/charlesvdd/administrator-neomnia.git
cd administrator-neomnia

# 2. Rends le script exécutable
chmod +x git-wrapper.sh

# 3. Lance-le
./git-wrapper.sh owner/repo [owner2/repo2 ...]
```

---

## 📋 Modes de fonctionnement

1. **Première exécution** :
   • Demande d’une passphrase → création du fichier `~/.config/neomnia/.passphrase`
   • Demande d’un token GitHub → chiffrement dans `~/.config/neomnia/.token.enc`
2. **Exécutions suivantes** :
   • Déchiffrement transparent du token
   • Authentification silencieuse (`gh auth login --with-token`)
   • Clonage ou `pull` sur chaque dépôt passé en argument
3. **Logs** : un fichier horodaté est créé dans `$HOME/github-backups`.

---

## 🖥️ Exemple de sortie

```
 _   _ ______ ______ ___  __  __ _ _           
| \ | |  ____|  ____|__ \|  \/  (_) |          
|  \| | |__  | |__     ) | \  / |_| | ___  ___ 
| . ` |  __| |  __|   / /| |\/| | | |/ _ \/ __|
| |\  | |____| |____ / /_| |  | | | |  __/\__ \
|_| \_|______|______|____|_|  |_|_|_|\___||___/

        🚀 GitHub Wrapper v1.0.0 - by NEOMNIA™

🧩 ÉTAPE 1/5 – Vérification de la passphrase … ✅
🧩 ÉTAPE 2/5 – Chargement du token GitHub … ✅
🧩 ÉTAPE 3/5 – Authentification GitHub CLI … ✅
🧩 ÉTAPE 4/5 – Récupération des dépôts … ✅
🧩 ÉTAPE 5/5 – Ajustement des permissions … ✅
🎉 NEOMNIA: Sauvegarde complétée avec succès.
```

---

## 💡 Bonnes pratiques

* **Ne publie jamais** le fichier `~/.config/neomnia/.token.enc` : il est local.
* Donne uniquement les **scopes nécessaires** à ton PAT (souvent `repo`, `workflow`, `read:org`).
* Configure un **cron** ou un **systemd timer** pour automatiser les sauvegardes.
* Incrémente la variable `VERSION` du script pour chaque release majeure.

---

## 🗺️ Roadmap

* [ ] Menu TUI (dialog/whiptail)
* [ ] Notifications Slack/Discord/email
* [ ] Support multi-utilisateur & multi-token
* [ ] Intégration GitOps pour déploiement continu

---

## 📜 Licence

Ce projet est distribué sous licence **MIT**.
Copyright © 2025 **NEOMNIA™**

Pour toute question : [contact@neomnia.company](mailto:contact@neomnia.net)
