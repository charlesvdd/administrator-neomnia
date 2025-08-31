#!/usr/bin/env bash
set -Eeuo pipefail
###############################################################################
#  Script d’installation et configuration système – Application: inital vps   #
#  Licence : (c) Charles Van den Driessche – @neomnia                         #
#                                                                             #
#  Permission est accordée d’utiliser, copier, modifier et distribuer ce      #
#  script, avec mention de l’auteur. Le script est fourni "en l’état", sans   #
#  garantie d’aucune sorte.                                                   #
#                                                                             #
#  Auteur  : @neomnia                                                         #
#  Version : 1.1 (adapté pour Azure)                                          #
###############################################################################

# ——————— Paramètres d’app et journalisation ———————
APP_NAME="inital vps"
BRAND_ONE="Neomnia"
BRAND_TWO="Neo-inital"
LOGFILE="/var/log/${APP_NAME// /-}-setup.log"
START_TS="$(date +%s)"

# Redirection vers log + console
mkdir -p "$(dirname "$LOGFILE")"
exec > >(tee -a "$LOGFILE") 2>&1

# ——————— Couleurs ———————
RED="\033[31m"; GREEN="\033[32m"; YELLOW="\033[33m"; BLUE="\033[34m"
MAGENTA="\033[35m"; CYAN="\033[36m"; BOLD="\033[1m"; RESET="\033[0m"

# ——————— Préfixe de log ———————
prefix() {
  echo -e "${CYAN}[${BRAND_ONE}]${RESET}${CYAN}[${BRAND_TWO}]${RESET}${CYAN}[${APP_NAME}]${RESET} $(date +%H:%M:%S)"
}

log()  { echo -e "$(prefix) $*"; }
ok()   { echo -e "$(prefix) ${GREEN}✔${RESET} $*"; }
warn() { echo -e "$(prefix) ${YELLOW}⚠${RESET} $*"; }
err()  { echo -e "$(prefix) ${RED}✖${RESET} $*" >&2; }

# ——————— Gestion d’erreurs & sortie ———————
CURRENT_STEP="initialisation"
on_error() {
  local exit_code=$?
  local line_no=$1
  local cmd=${2:-"N/A"}
  err "Échec pendant l’étape: ${BOLD}${CURRENT_STEP}${RESET} (ligne ${line_no})"
  err "Dernière commande: ${BOLD}${cmd}${RESET}"
  err "Journal complet: ${LOGFILE}"
  echo
  exit "$exit_code"
}

on_exit() {
  local code=$?
  local end_ts
  end_ts="$(date +%s)"
  local duration=$(( end_ts - START_TS ))
  if [ "$code" -eq 0 ]; then
    ok "Setup terminé sans erreur ✅ (durée: ${duration}s)."
    ok "Journal: ${LOGFILE}"
  else
    err "Setup terminé avec erreurs ❌ (durée: ${duration}s)."
    err "Consulte le journal: ${LOGFILE}"
  fi
}

trap 'on_error $LINENO "$BASH_COMMAND"' ERR
trap 'on_exit' EXIT

# ——————— Vérif shell ———————
if [ -z "${BASH_VERSION:-}" ]; then
  log "Bash requis → relance sous bash..."
  exec bash "$0" "$@"
fi

# ——————— Vérif root ———————
CURRENT_STEP="vérification des privilèges"
if [ "${EUID:-$(id -u)}" -ne 0 ]; then
  err "Ce script doit être exécuté en root."
  exit 1
fi
ok "Privilèges root confirmés."

# ——————— Hostname (commenté pour Azure) ———————
# CURRENT_STEP="configuration du hostname"
# read -rp "$(echo -e "$(prefix) ${BOLD}Nom du nouvel hostname :${RESET} ")" NEW_HOSTNAME
# log "Configuration du hostname → ${NEW_HOSTNAME}"
# hostnamectl set-hostname "$NEW_HOSTNAME"
# if grep -q "^[[:space:]]*127\.0\.1\.1" /etc/hosts; then
#   sed -i "s/^[[:space:]]*127\.0\.1\.1.*/127.0.1.1\t${NEW_HOSTNAME}/" /etc/hosts
# else
#   echo -e "127.0.1.1\t${NEW_HOSTNAME}" >> /etc/hosts
# fi
# ok "Hostname configuré en ${NEW_HOSTNAME}"

# ——————— Utilisateur & Groupe (simplifié pour Azure) ———————
CURRENT_STEP="configuration utilisateur et groupe"
NEW_USER_NAME="azureuser"  # Utilisateur par défaut sur Azure
GROUP_NAME="gitusers"      # Groupe par défaut

if ! id "$NEW_USER_NAME" &>/dev/null; then
  err "L’utilisateur ${NEW_USER_NAME} n'existe pas. Vérifiez votre configuration Azure."
  exit 1
else
  ok "Utilisateur ${NEW_USER_NAME} déjà existant."
fi

if ! getent group "$GROUP_NAME" >/dev/null; then
  groupadd "$GROUP_NAME"
  ok "Groupe ${GROUP_NAME} créé."
else
  warn "Groupe ${GROUP_NAME} déjà existant."
fi

echo "%${GROUP_NAME} ALL=(ALL) NOPASSWD:ALL" | tee "/etc/sudoers.d/${GROUP_NAME}" >/dev/null
usermod -aG "$GROUP_NAME" "$NEW_USER_NAME"
ok "Utilisateur ${NEW_USER_NAME} ajouté au groupe ${GROUP_NAME}"

# ——————— Paquets & UFW ———————
CURRENT_STEP="mise à jour système et packages"
log "Mise à jour du système…"
export DEBIAN_FRONTEND=noninteractive
apt-get update -y && apt-get upgrade -y
ok "Système à jour."

log "Installation des outils de base (acl, curl, git, ufw, tree, wget, jq)…"
apt-get install -y acl curl git ufw tree wget jq
ok "Paquets installés."

CURRENT_STEP="droits /opt avec ACL"
chown -R root:"$GROUP_NAME" /opt 2>/dev/null || true
chmod -R 2775 /opt 2>/dev/null || true
setfacl -R -m g:"$GROUP_NAME":rwx /opt
ok "ACL appliquées sur /opt pour le groupe ${GROUP_NAME}"

CURRENT_STEP="pare-feu UFW"
log "Configuration du pare-feu UFW…"
ufw allow OpenSSH >/dev/null 2>&1 || true
ufw --force enable
ok "Pare-feu activé."

# ——————— Git & GitHub API ———————
CURRENT_STEP="configuration Git"
read -rp "$(echo -e "$(prefix) ${BOLD}Email Git :${RESET} ")" GIT_EMAIL
read -rp "$(echo -e "$(prefix) ${BOLD}Nom Git :${RESET} ")" GIT_CONF_USERNAME
git config --global user.email "$GIT_EMAIL"
git config --global user.name "$GIT_CONF_USERNAME"
ok "Configuration Git appliquée."

CURRENT_STEP="validation clé GitHub"
read -rp "$(echo -e "$(prefix) ${BOLD}GitHub username:${RESET} ")" GITHUB_USERNAME
read -srp "$(echo -e "$(prefix) ${BOLD}GitHub API key:${RESET} ")" GITHUB_API_KEY; echo
log "Vérification des droits GitHub API…"
RESPONSE="$(curl -sS -H "Authorization: token ${GITHUB_API_KEY}" https://api.github.com/user || true)"

if echo "$RESPONSE" | jq -e '.login' >/dev/null 2>&1; then
  USER_LOGIN="$(echo "$RESPONSE" | jq -r '.login')"
  ok "Connexion GitHub OK → ${USER_LOGIN}"
else
  err "Impossible de valider la clé API GitHub."
  exit 1
fi

# ——————— Vérification finale ———————
CURRENT_STEP="vérification finale"
echo -e "\n${MAGENTA}${BOLD}############## Vérification finale — ${APP_NAME} ##############${RESET}"
ok "Utilisateur Azure existant: ${NEW_USER_NAME}"
ok "Groupe appliqué à /opt avec ACL: ${GROUP_NAME}"
[[ -n "${USER_LOGIN:-}" ]] && ok "GitHub API valide pour: ${USER_LOGIN}"
echo -e "${MAGENTA}${BOLD}##############   Setup complet   ##############${RESET}\n"
