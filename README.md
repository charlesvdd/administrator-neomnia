# 🚀 Neomia Studio — Next.js Installer

**Script d'installation automatisée de Next.js (TypeScript + ESLint + Prettier) en mode utilisateur (sans sudo).**
Développé par **Charles Van den driessche** pour **Neomia Studio**.

---

## 📜 Description
Ce script Bash installe un projet **Next.js** avec :
- **TypeScript** et **ESLint** (via `create-next-app`).
- **Prettier** pour le formatage de code.
- **Git** initialisé avec un premier commit.
- **NVM** et **Node.js v18+** (si non présents).
- Installation dans `~/opt/<nom-du-projet>`.

**Licence** : Propriétaire — Charles Van den driessche (2025).

---

## 🔗 Lien Raw (Exécution Directe)
Pour exécuter le script **directement depuis GitHub** (sans cloner le dépôt) :
```bash
bash <(curl -s https://raw.githubusercontent.com/charlesvdd/administrator-neomnia/react-next-project/react.sh)
