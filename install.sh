#!/usr/bin/env bash
#
# install.sh – Téléchargement et installation depuis un RAW GitHub
#
# Usage (en une seule ligne) :
#   sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/charlesvdd/administrator-neomnia/api-key-github/install.sh)"
#

set -euo pipefail

# 1. Vérifier qu'on est root
if [[ "$EUID" -ne 0 ]]; then
  echo "❌ Ce script doit être exécuté en tant que root."
  echo "   Relancez-le avec : sudo $0"
  exit 1
fi

# 2. Demander les informations GitHub
echo "===== Informations GitHub ====="
read -p "Nom d’utilisateur GitHub : " GITHUB_USER
read -s -p "Clé API GitHub (input masqué) : " GITHUB_API_KEY
echo -e "\n"   # passage à la ligne après saisie masquée

# Exporter pour que les fonctions ultérieures puissent les utiliser
export GITHUB_USER GITHUB_API_KEY

# 3. Définir une fonction d’affichage de titre pour chaque étape
function stage_title() {
  local num="$1"
  local msg="$2"
  echo -e "\n===== Étape $num: $msg ====="
}

# 4. Fonction de téléchargement depuis RAW GitHub
# Arguments :
#   $1 = dépôt (ex. "administrator-neomnia")
#   $2 = branche (ex. "api-key-github")
#   $3 = chemin/vers/fichier.dans.repo (ex. "scripts/mon-script.sh")
#   $4 = destination locale (ex. "/usr/local/bin/mon-script.sh")
function download_from_raw() {
  local repo="$1"
  local branch="$2"
  local filepath="$3"
  local dest="$4"
  local raw_url="https://raw.githubusercontent.com/${GITHUB_USER}/${repo}/${branch}/${filepath}"

  echo "→ Téléchargement : ${raw_url}"
  curl -fSL -H "Authorization: token ${GITHUB_API_KEY}" \
       "${raw_url}" -o "${dest}"
  chmod +x "${dest}"
  echo "✔ Téléchargé et rendu exécutable : ${dest}"
}

# 5. Étapes d’installation en plusieurs « stages »

# Étape 1 : Mise à jour du système et prérequis
stage_title 1 "Mise à jour système et dépendances"
apt-get update -y
apt-get upgrade -y
# Installez ici ce qui est nécessaire, par exemple curl, git, etc.
apt-get install -y curl git

# Étape 2 : Téléchargement du(s) script(s) principal(aux)
stage_title 2 "Téléchargement du(s) script(s) depuis GitHub"
# Exemple : récupérer un script nommé ‘install-myapp.sh’ dans « scripts/ »
# du dépôt ‘administrator-neomnia’ sur la branche ‘api-key-github’, et le placer en /usr/local/bin
download_from_raw "administrator-neomnia" "api-key-github" "scripts/install-myapp.sh" "/usr/local/bin/install-myapp.sh"

# Si vous aviez plusieurs fichiers à récupérer, répétez download_from_raw pour chacun :
# download_from_raw "administrator-neomnia" "api-key-github" "scripts/configure.sh" "/usr/local/bin/configure.sh"
# download_from_raw "autre-depot"      "main"             "deploy.sh"          "/usr/local/bin/deploy.sh"

# Étape 3 : Exécution du/des script(s) téléchargé(s)
stage_title 3 "Exécution des scripts téléchargés"
if [[ -x "/usr/local/bin/install-myapp.sh" ]]; then
  echo "→ Lancement : /usr/local/bin/install-myapp.sh"
  # Ici, on transmet éventuellement la clé API et l’utilisateur GitHub si le script en a besoin
  GITHUB_USER="${GITHUB_USER}" GITHUB_API_KEY="${GITHUB_API_KEY}" \
    /usr/local/bin/install-myapp.sh
else
  echo "⚠️ Le script /usr/local/bin/install-myapp.sh n'existe pas ou n'est pas exécutable."
fi

# Ajouter d'autres lancements si vous avez plusieurs scripts
# if [[ -x "/usr/local/bin/configure.sh" ]]; then
#   GITHUB_USER="${GITHUB_USER}" GITHUB_API_KEY="${GITHUB_API_KEY}" \
#     /usr/local/bin/configure.sh
# fi

# Étape 4 : Nettoyage ou configuration finale
stage_title 4 "Nettoyage / Configurations finales"
# Par exemple :
# - supprimer des fichiers temporaires
# - créer un utilisateur de service
# - copier des fichiers de config vers /etc/…
# - redémarrer un service systemd
#
# Exemple basique : on crée un dossier /opt/monapp et on copie un binaire
# mkdir -p /opt/monapp
# cp /usr/local/bin/monapp /opt/monapp/

echo -e "\n✅ Installation terminée !"
