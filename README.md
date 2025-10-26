**TL;DR** : voici un **README prêt à publier** pour ton script d’installation Next.js (NEOMNIA ACSS), incluant le **lancement “RAW”** direct depuis GitHub pour la branche `install-next-project`.

---

### Plan (pseudocode)

* Titre + résumé.
* One-liner exécution RAW (curl / wget).
* Fonctionnalités.
* Prérequis.
* Ce que fait le script (étapes).
* Saisie des versions **Node** & **Next**.
* Permissions & sécurité (groupe, ACL, setgid).
* Utilisation détaillée + exemples.
* Post-install (dev, build, prod).
* Désinstallation.
* Dépannage (FAQ rapide).
* Licence & attributions.

````markdown
# NEOMNIA ACSS — Installateur Next.js sous /opt

> Installe un projet **Next.js** dans **/opt/<projet>**, crée un **groupe** homonyme avec **droits complets** (ACL + setgid), et **journalise** chaque ligne avec le préfixe `[ NEOMNIA ]`. Sélection guidée des **versions Node** (via **nvm**) et **Next**.

---

## 🚀 Lancement “RAW” (exécution directe)

> Branche : `install-next-project` — dépôt : `charlesvdd/administrator-neomnia`

**curl**
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/charlesvdd/administrator-neomnia/install-next-project/next-project)
````

**wget**

```bash
bash <(wget -qO- https://raw.githubusercontent.com/charlesvdd/administrator-neomnia/install-next-project/next-project)
```

> Astuce : ajoute `-S` pour un mode “strict” sur `curl`/`wget` si tu veux échouer plus fort sur HTTP.

---

## ✨ Fonctionnalités

* Création d’un **projet Next.js** (App Router, TS, Tailwind, ESLint, Turbopack) dans `/opt/<projet>`.
* Demande interactive du **nom de projet** → normalisation (`kebab-case`).
* **Node** via **nvm** : `latest-lts` (défaut), version précise (`22.10.0`…), ou `skip` (utiliser Node existant).
* **Next** : `latest` (défaut) ou version précise (`16.x.y`).
* **Groupe Unix** homonyme au projet, **setgid** sur les dossiers, **ACL** par défaut si `setfacl` présent.
* **Logs** alignés et préfixés `[ NEOMNIA ]` + **bannières** “NEOMNIA ACSS”.

---

## ✅ Prérequis

* Système : Ubuntu/Debian-like (root ou `sudo` requis).
* Réseau sortant vers GitHub (pour **nvm** et **create-next-app**).
* Outils : `bash`, `sed`, `curl`/`wget`, `setfacl` (optionnel mais recommandé).

---

## 🧩 Ce que fait le script (overview)

1. Vérifie `root/sudo`.
2. Demande **nom de projet** → définit `PROJECT_DIR=/opt/<projet>` et `GROUP_NAME=<projet>`.
3. **Node** : selon ton choix

   * `latest-lts` via **nvm** (installé auto si absent)
   * **version précise** via nvm
   * `skip` (exige Node ≥ 20.9)
4. Vérifie `npx`.
5. **Next** : `latest` ou version précise.
6. Crée **groupe** `<projet>` et **dossier** `/opt/<projet>` (owner `root:<groupe>`, `chmod 2775`).
7. Scaffold `create-next-app@latest` dans `/opt/<projet>`.
8. Si version de **Next** spécifique : `npm i -E next@<version>`.
9. Applique **permissions** : `chown -R root:<groupe>`, `chmod -R g+rwX`, `setgid` sur dossiers, **ACL** par défaut si dispo.
10. Affiche **récap** + commandes utiles.

---

## 🔢 Choix des versions

* **Node**

  * `latest-lts` *(défaut)* : installe et active la dernière LTS via **nvm**.
  * `22.10.0` *(exemple)* : installe/active cette version précise.
  * `skip` : n’installe pas Node (tu dois déjà avoir **Node ≥ 20.9** + **npx**).

* **Next**

  * `latest` *(défaut)*
  * `16.1.3` *(exemple)* : le script “pin” `next@16.1.3` après le scaffold.

---

## 🔐 Permissions & sécurité

* **Groupe** `<projet>` créé si absent.
* Dossier `/opt/<projet>` : `chmod 2775` → **setgid** pour que tous les nouveaux fichiers héritent du groupe.
* **ACL** (si `setfacl` présent) : règles par défaut `g:<projet>:rwX` → droits de groupe persistants.
* Ajout d’un utilisateur au groupe :

  ```bash
  sudo usermod -aG <projet> <user> && echo "Reconnexion requise pour prendre effet"
  ```

---

## 🛠️ Utilisation

### 1) Exécution interactive

```bash
# Méthode RAW recommandée
bash <(curl -fsSL https://raw.githubusercontent.com/charlesvdd/administrator-neomnia/install-next-project/next-project)
```

Tu répondras aux invites :

* **Nom du projet** (ex. `mon-app` → `/opt/mon-app` + groupe `mon-app`)
* **Version Node** (`latest-lts` / `22.10.0` / `skip`)
* **Version Next** (`latest` / `16.1.3`)

### 2) Exécution locale

```bash
# Cloner (optionnel)
git clone -b install-next-project https://github.com/charlesvdd/administrator-neomnia.git
cd administrator-neomnia
chmod +x next-project
sudo ./next-project
```

---

## ▶️ Post-installation

* **Dev**

  ```bash
  cd /opt/<projet>
  npm run dev
  ```

* **Build + Start (prod simple)**

  ```bash
  cd /opt/<projet>
  npm run build
  npm run start -- -p 3000
  ```

> Besoin d’un **service systemd** (PM2 ou `node`) ? Voir “Aller plus loin”.

---

## 🧹 Désinstallation

```bash
sudo systemctl stop <service> 2>/dev/null || true
sudo rm -rf /opt/<projet>
# Optionnel : supprimer le groupe (si plus utilisé)
sudo groupdel <projet> 2>/dev/null || true
```

---

## 🩺 Dépannage rapide

* **Node non trouvé / version < 20.9**
  → Relance le script et choisis `latest-lts` (installe/active via nvm).

* **`setfacl` absent**
  → Les ACL ne seront pas posées (les droits `chmod + setgid` restent en place).
  → Installer : `sudo apt-get install acl`.

* **`/opt/<projet>` existe déjà**
  → Le script s’arrête pour éviter l’écrasement. Supprime ou choisis un autre nom.

---

## 📜 Licence & attributions

* Basé sur le dépôt **administrator-neomnia** (branche `install-next-project`).
* Exécution RAW et structure référencées depuis GitHub.
* Licence du dépôt : MIT.

```

> Source du dépôt/branche pour l’exécution RAW : :contentReference[oaicite:0]{index=0}

**a.** Tu veux que je **génère le `README.md` dans le repo** (avec un bloc “systemd/PM2” prêt à l’emploi) ?  
**b.** On ajoute une **section sécurité** (audit sudoers, `umask`, `.nvmrc`, `.npmrc` lock) + **exemples pnpm/yarn/bun** ?
::contentReference[oaicite:1]{index=1}
```
