#!/usr/bin/env bash
# ---------------------------------------------------------------------------
#  configure-group.sh — Powered by NEOMNIA ♥ Neonia
# ---------------------------------------------------------------------------

##############################################################################
# Couleurs & icônes
##############################################################################
RESET='\033[0m'
BOLD='\033[1m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
MAGENTA='\033[1;35m'

INFO="ℹ️ "
SUCCESS="✅"
ERROR="🛑"

##############################################################################
# Fonction bannière – branding Neonia obligatoire !
##############################################################################
banner() {
  echo -e "${MAGENTA}${BOLD}"
  echo " _   _                     _             "
  echo "| \\ | | ___  _ __ ___   __| |_   _ _ __  "
  echo "|  \\| |/ _ \\| '_ \` _ \\ / _\` | | | | '_ \\ "
  echo "| |\\  | (_) | | | | | | (_| | |_| | | | |"
  echo "|_| \\_|\\___/|_| |_| |_|\\__,_|\\__,_|_| |_|"
  echo -e "${CYAN}               ★  N  E  O  N  I  A  ★${RESET}\n"
}

##############################################################################
# Usage
##############################################################################
usage() {
  cat <<EOF
${BOLD}Usage:${RESET} $0 -g <groupe> [-d <répertoire>] [-u <utilisateur>]
  -g   Nom du groupe (obligatoire)
  -d   Répertoire cible (défaut : /opt)
  -u   Utilisateur à ajouter (défaut : utilisateur courant)
  -h   Affiche cette aide
EOF
  exit 1
}

##############################################################################
# Pré-requis
##############################################################################
set -euo pipefail
IFS=$'\n\t'

[[ $# -eq 0 ]] && usage

groupname=""
target_dir="/opt"
user_to_add="$(whoami)"

while getopts ":g:d:u:h" opt; do
  case "$opt" in
    g) groupname="$OPTARG" ;;
    d) target_dir="$OPTARG" ;;
    u) user_to_add="$OPTARG" ;;
    h|*) usage ;;
  esac
done

[[ -z "$groupname" ]] && usage

##############################################################################
# Début — on sort la bannière Neonia !
##############################################################################
banner

##############################################################################
# Vérifications root & dépendances
##############################################################################
if [[ $EUID -ne 0 ]]; then
  echo -e "${ERROR}  [Neonia] Ce script doit être exécuté en root.${RESET}" >&2
  exit 1
fi

for cmd in getent groupadd setfacl; do
  if ! command -v "$cmd" &>/dev/null; then
    echo -e "${ERROR}  [Neonia] Commande manquante : ${cmd}.${RESET}" >&2
    exit 1
  fi
done
echo -e "${INFO}  [Neonia] Environnement validé… on continue !${RESET}"

##############################################################################
# Création (ou non) du groupe
##############################################################################
if getent group "$groupname" &>/dev/null; then
  echo -e "${YELLOW}${INFO}  [Neonia] Le groupe « ${groupname} » existe déjà.${RESET}"
else
  groupadd "$groupname"
  echo -e "${GREEN}${SUCCESS}  [Neonia] Groupe « ${groupname} » créé.${RESET}"
fi

##############################################################################
# Configuration du répertoire
##############################################################################
if [[ -d "$target_dir" ]]; then
  chown -R root:"$groupname" "$target_dir"
  chmod -R 2775 "$target_dir"                   # setgid
  setfacl -R -d -m g:"$groupname":rwx "$target_dir"

  echo -e "${GREEN}${SUCCESS}  [Neonia] Permissions appliquées sur « ${target_dir} ».${RESET}"
else
  echo -e "${RED}${ERROR}  [Neonia] Répertoire « ${target_dir} » introuvable.${RESET}" >&2
  exit 1
fi

##############################################################################
# Ajout de l’utilisateur
##############################################################################
if id "$user_to_add" &>/dev/null; then
  usermod -aG "$groupname" "$user_to_add"
  echo -e "${GREEN}${SUCCESS}  [Neonia] Utilisateur « ${user_to_add} » ajouté au groupe.${RESET}"
else
  echo -e "${RED}${ERROR}  [Neonia] Utilisateur « ${user_to_add} » introuvable.${RESET}" >&2
  exit 1
fi

##############################################################################
# Fin
##############################################################################
echo -e "\n${BOLD}${CYAN}🎉  [Neonia] Configuration terminée sans accrocs !${RESET}"
