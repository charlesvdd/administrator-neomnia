#!/usr/bin/env bash
# ---------------------------------------------------------------------------
#  configure-group.sh — Powered by NEOMNIA ♥ Neonia
# ---------------------------------------------------------------------------

set -euo pipefail
IFS=$'\n\t'

# ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# Couleurs & icônes
# ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
RESET='\033[0m'; BOLD='\033[1m'
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[1;36m'; MAGENTA='\033[1;35m'
INFO="ℹ️ "; SUCCESS="✅"; ERROR="🛑"

banner() {
  echo -e "${MAGENTA}${BOLD}"
  echo ' _   _                     _             '
  echo '| \ | | ___  _ __ ___   __| |_   _ _ __  '
  echo '|  \| |/ _ \| '"'"'_`'"'"' _ \ / _` | | | | '"'"'_ \ '"'
  echo '| |\  | (_) | | | | | | (_| | |_| | | | |'
  echo '|_| \_|\___/|_| |_| |_|\__,_|\__,_|_| |_|'
  echo -e "${CYAN}              ★  N  E  O  N  I  A  ★${RESET}\n"
}

usage() {
cat <<EOF
${BOLD}Usage:${RESET} $0 [-g <groupe>] [-d <répertoire>] [-u <utilisateur>] [-s] [-y]
  -g   Nom du groupe (si absent, demande interactive)
  -d   Répertoire cible (défaut : /opt)
  -u   Utilisateur à ajouter (défaut : utilisateur courant)
  -s   Donne le droit sudo au groupe sans poser la question
  -y   Non interactif : « oui » à tout (equiv. réponse par défaut)
  -h   Affiche cette aide
EOF
exit 1
}

# ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# Parsing des options
# ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
groupname=""                # vide ⇒ on demandera
target_dir="/opt"
user_to_add="$(whoami)"
sudo_flag=0                 # 1 = accorde sudo
auto_yes=0                  # 1 = non interactif

while getopts ":g:d:u:syh" opt; do
  case "$opt" in
    g) groupname="$OPTARG" ;;
    d) target_dir="$OPTARG" ;;
    u) user_to_add="$OPTARG" ;;
    s) sudo_flag=1 ;;
    y) auto_yes=1 ;;
    h|*) usage ;;
  esac
done

# Si -g n’a pas été fourni, demander à l’utilisateur (sauf -y)
if [[ -z "$groupname" && $auto_yes -eq 0 ]]; then
  read -rp "🔤  [Neonia] Entrez le nom du groupe à créer : " groupname
fi

[[ -z "$groupname" ]] && { echo "[Neonia] Aucun nom de groupe reçu, abandon." >&2; exit 1; }

# ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# Démarrage
# ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
banner

[[ $EUID -ne 0 ]] && { echo -e "${ERROR}  [Neonia] Exécute-moi en root/sudo.${RESET}"; exit 1; }

for cmd in getent groupadd setfacl; do
  command -v "$cmd" >/dev/null || {
    echo -e "${ERROR}  [Neonia] Commande manquante : $cmd.${RESET}"; exit 1; }
done
echo -e "${INFO}  [Neonia] Pré-requis OK.${RESET}"

# ---------------------------------------------------------------------------
# 1) Création du groupe
# ---------------------------------------------------------------------------
if getent group "$groupname" &>/dev/null; then
  echo -e "${YELLOW}${INFO}  [Neonia] Le groupe « $groupname » existe déjà.${RESET}"
else
  groupadd "$groupname"
  echo -e "${GREEN}${SUCCESS}  [Neonia] Groupe « $groupname » créé.${RESET}"
fi

# ---------------------------------------------------------------------------
# 2) Sudoers (demande si ni -s ni -y)
# ---------------------------------------------------------------------------
if [[ $sudo_flag -eq 0 && $auto_yes -eq 0 ]]; then
  read -rp "⚡  [Neonia] Donner les privilèges sudo au groupe « $groupname » ? (y/N) " resp
  [[ $resp =~ ^[Yy]$ ]] && sudo_flag=1
fi

if [[ $sudo_flag -eq 1 ]]; then
  echo "%$groupname ALL=(ALL:ALL) ALL" >"/etc/sudoers.d/$groupname"
  chmod 0440 "/etc/sudoers.d/$groupname"
  echo -e "${GREEN}${SUCCESS}  [Neonia] Sudo accordé à « $groupname ».${RESET}"
fi

# ---------------------------------------------------------------------------
# 3) Répertoire cible
# ---------------------------------------------------------------------------
if [[ -d "$target_dir" ]]; then
  chown -R root:"$groupname" "$target_dir"
  chmod -R 2775 "$target_dir"
  setfacl -R -d -m g:"$groupname":rwx "$target_dir"
  echo -e "${GREEN}${SUCCESS}  [Neonia] Permissions appliquées sur « $target_dir ».${RESET}"
else
  echo -e "${RED}${ERROR}  [Neonia] Répertoire « $target_dir » introuvable.${RESET}"; exit 1
fi

# ---------------------------------------------------------------------------
# 4) Ajout de l’utilisateur
# ---------------------------------------------------------------------------
if id "$user_to_add" &>/dev/null; then
  usermod -aG "$groupname" "$user_to_add"
  echo -e "${GREEN}${SUCCESS}  [Neonia] Utilisateur « $user_to_add » ajouté au groupe.${RESET}"
else
  echo -e "${RED}${ERROR}  [Neonia] Utilisateur « $user_to_add » introuvable.${RESET}"; exit 1
fi

echo -e "\n${BOLD}${CYAN}🎉  [Neonia] Installation terminée sans accrocs !${RESET}"
