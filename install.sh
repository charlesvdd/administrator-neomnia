#!/usr/bin/env bash
#
# install.sh – Script d’installation complet (tout-en-un)
#
# Usage (en une seule ligne depuis n’importe où) :
#   sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/charlesvdd/administrator-neomnia/api-key-github/install.sh)"
#

set -euo pipefail

# 1. Vérifier qu’on est exécuté en tant que root
if [[ "$EUID" -ne 0 ]]; then
  echo "❌ Ce script doit être exécuté en root."
  echo "   Relancez avec : sudo $0"
  exit 1
fi

# 2. Demander les identifiants GitHub
echo "===== [Étape 0] — Informations GitHub ====="
read -p "Nom d’utilisateur GitHub : " GITHUB_USER
read -s -p "Clé API GitHub (input masqué) : " GITHUB_API_KEY
echo -e "\n"   # saut de ligne après saisie masquée

# Exporter pour que les commandes suivantes (git, curl…) puissent l’utiliser
export GITHUB_USER
export GITHUB_API_KEY

# 3. Fonction utilitaire pour afficher un titre d’étape
function stage() {
  local num="$1"; shift
  local msg="$*"
  echo -e "\n===== [Étape $num] — $msg ====="
}

# -------------------------------
# 4. Exemple de tâches d’installation
# -------------------------------

stage 1 "Mise à jour du système et installation des dépendances de base"
apt-get update -y
apt-get upgrade -y
apt-get install -y curl git ca-certificates

# (Vous pouvez y ajouter d’autres paquets nécessaires, par ex. build-essential, unzip, etc.)

# -------------------------------
# 5. Exemple : clonage du dépôt ⇒ si vous voulez récupérer du contenu supplémentaire
# -------------------------------
# Ici on clone votre dépôt (privé ou public) en utilisant le couple USER:API_KEY.
# Remplacez “administrator-neomnia” par le nom exact du dépôt si besoin.
#
# On clone dans /opt/administrator-neomnia, mais vous pouvez changer le chemin.
stage 2 "Clonage du dépôt GitHub dans /opt/administrator-neomnia"
REPO="administrator-neomnia"
TARGET_DIR="/opt/${REPO}"
if [[ -d "$TARGET_DIR" ]]; then
  echo "→ Le dossier ${TARGET_DIR} existe déjà, on le met à jour (git pull)…"
  git -C "$TARGET_DIR" pull
else
  echo "→ Clonage depuis GitHub : ${GITHUB_USER}/${REPO}"
  git clone "https://${GITHUB_USER}:${GITHUB_API_KEY}@github.com/${GITHUB_USER}/${REPO}.git" "$TARGET_DIR"
fi

# -------------------------------
# 6. Exemple : exécution d’un script interne s’il existe
# -------------------------------
# Supposons que, dans votre repo, vous ayez un fichier appelé setup.sh à la racine
# (ou un autre nom). Si c’est le cas, vous pouvez l’appeler ensuite.
#
# Vérifiez que le script existe et est exécutable, sinon ajustez le chemin ou nom.
stage 3 "Exécution du script interne (s’il est présent)"
INTERNAL_SCRIPT="${TARGET_DIR}/setup.sh"
if [[ -f "$INTERNAL_SCRIPT" ]]; then
  chmod +x "$INTERNAL_SCRIPT"
  echo "→ Lancement de ${INTERNAL_SCRIPT}"
  # Transmettre éventuellement les variables d’env. GitHub au script interne
  GITHUB_USER="${GITHUB_USER}" GITHUB_API_KEY="${GITHUB_API_KEY}" \
    bash "$INTERNAL_SCRIPT"
else
  echo "ℹ️ Aucun script setup.sh trouvé dans ${TARGET_DIR}. Vous pouvez ignorer cette étape."
fi

# -------------------------------
# 7. Exemple : installation de services / configurations personnalisées
# -------------------------------
# Ici, ajoutez tout ce qui vous sert pour préparer votre environnement VPS.
# Par exemple :
#
#   - Installer Docker :
#       stage X "Installation de Docker"
#       apt-get install -y docker.io
#       systemctl enable docker
#       systemctl start docker
#
#   - Installer et configurer nginx :
#       stage Y "Installation de nginx"
#       apt-get install -y nginx
#       systemctl enable nginx
#       systemctl restart nginx
#
#   - Ajouter un utilisateur de service, copier des fichiers de config, etc.
#
# Exemple générique :
stage 4 "Installation d’exemples de services (nginx + docker)"
# Docker
if ! command -v docker &>/dev/null; then
  apt-get install -y docker.io
  systemctl enable docker
  systemctl start docker
  echo "✔ Docker installé et démarré."
else
  echo "ℹ️ Docker est déjà installé."
fi

# nginx
if ! command -v nginx &>/dev/null; then
  apt-get install -y nginx
  systemctl enable nginx
  systemctl start nginx
  echo "✔ nginx installé et démarré."
else
  echo "ℹ️ nginx est déjà installé."
fi

# -------------------------------
# 8. Nettoyage ou configuration finale
# -------------------------------
stage 5 "Nettoyage / tâches finales"
# Exemple : suppression des paquets qui ne servent plus
apt-get autoremove -y
apt-get clean

echo -e "\n✅ L’installation est terminée."
