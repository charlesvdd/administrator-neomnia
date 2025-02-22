Voici un **README** détaillé expliquant le processus de déploiement de l'utilisateur `neoweb` sur un serveur Ubuntu via **GitHub et SSH**.

---

## 🚀 **Déploiement Automatisé de l'Utilisateur `neoweb`**

Ce projet permet d'**automatiser la création et la configuration de l'utilisateur `neoweb` sur un serveur Ubuntu**.  
Il inclut les étapes suivantes :

✅ Génération d'une **clé SSH** pour l'accès à GitHub.  
✅ Ajout **manuel** de la clé publique sur GitHub.  
✅ Configuration des **permissions SSH** et de l'accès sécurisé.  
✅ Vérification de la **connexion SSH à GitHub**.  
✅ Clonage du **dépôt GitHub** contenant les fichiers de configuration.  
✅ Exécution du **script `install.sh`** pour créer et configurer l'utilisateur `neoweb`.

---

## 📌 **1️⃣ Installation**
### **Prérequis**
- Serveur **Ubuntu** avec accès SSH.
- Un compte **GitHub** avec accès au dépôt privé.
- L'utilisateur de base **`ubuntu`** avec accès `sudo`.

### **Étapes**
1️⃣ **Cloner ce dépôt sur votre serveur** :
```bash
git clone git@github.com:neoweb2212/users-neoweb.git ~/users-neoweb
cd ~/users-neoweb
```

2️⃣ **Rendre le script exécutable** :
```bash
chmod +x deploy.sh
```

3️⃣ **Exécuter le script** :
```bash
bash deploy.sh
```

---

## 📌 **2️⃣ Ajout de la Clé SSH sur GitHub**
Lors de l'exécution, le script **génère une nouvelle clé SSH** et affiche sa **clé publique**.  
**Copiez cette clé** et ajoutez-la sur **GitHub** :

1️⃣ Aller sur **[GitHub → SSH and GPG keys](https://github.com/settings/keys)**.  
2️⃣ Cliquez sur **"New SSH Key"**.  
3️⃣ Donnez un nom (ex: "VPS OVH") et **collez la clé affichée**.  
4️⃣ Cliquez sur **"Add SSH Key"**.

---

## 📌 **3️⃣ Vérification de la Connexion SSH à GitHub**
Après l'ajout de la clé, **testez la connexion** :

```bash
ssh -T git@github.com
```

✅ Si tout fonctionne, le message suivant s'affichera :
```
Hi neoweb2212! You've successfully authenticated, but GitHub does not provide shell access.
```

---

## 📌 **4️⃣ Exécution du Script d'Installation**
Une fois la connexion SSH validée, le script **clone automatiquement le dépôt et exécute `install.sh`** pour finaliser la configuration :

```bash
cd ~/users-neoweb
bash install.sh
```

---

## 📌 **5️⃣ Ce que Fait `install.sh`**
- ✅ **Crée l'utilisateur `neoweb`** s'il n'existe pas.
- ✅ **Configure son accès SSH** en copiant la clé privée de `ubuntu`.
- ✅ **Applique les bonnes permissions SSH**.
- ✅ **Teste la connexion GitHub pour `neoweb`**.
- ✅ **Clone le dépôt dans `/home/neoweb/users-neoweb/`**.

---

## 🎯 **Résumé du Processus**
1️⃣ **Exécuter `deploy.sh`** sous `ubuntu`.  
2️⃣ **Ajouter la clé publique sur GitHub** (manuellement).  
3️⃣ **Vérifier la connexion SSH** (`ssh -T git@github.com`).  
4️⃣ **Cloner le dépôt et exécuter `install.sh`**.  
5️⃣ **L'utilisateur `neoweb` est prêt à utiliser GitHub !** 🎉  

---

## ❓ **Dépannage**
### **Problème de permission sur la clé SSH**
Erreur :
```
Permissions 0664 for '/home/ubuntu/.ssh/id_ed25519' are too open.
```
Solution :
```bash
chmod 600 ~/.ssh/id_ed25519
```

### **Échec de connexion SSH à GitHub**
Erreur :
```
git@github.com: Permission denied (publickey).
```
Solution :
1️⃣ Vérifiez que **la clé publique est bien ajoutée** sur GitHub.  
2️⃣ Assurez-vous que **SSH utilise la bonne clé** :
```bash
ssh -i ~/.ssh/id_ed25519 -T git@github.com
```

---

## 🛠 **Améliorations Possibles**
- ✅ **Automatisation de l'ajout de la clé sur GitHub** via l'API GitHub.
- ✅ **Ajout d'une vérification automatique** avant d'exécuter `install.sh`.
- ✅ **Possibilité d'ajouter plusieurs utilisateurs avec le même processus**.

---

## 📜 **Licence**
Ce projet est sous licence **MIT**.  
Créé par **neoweb2212**.

---

Avec ce **README**, tu as tout le guide détaillé pour comprendre et exécuter le processus de déploiement ! 🚀