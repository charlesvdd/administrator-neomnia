#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────
#  setup_neoweb.sh – Bootstrap propre d’un groupe + user Neoweb
#  Repo : https://github.com/charlesvdd/administrator-neomnia/tree/Groups
#  Licence : MIT
# ──────────────────────────────────────────────────────────────
set -Eeuo pipefail

VERSION="1.2.0"
SCRIPT_NAME="$(basename "$0")"

# ─── Couleurs ────────────────────────────────────────────────
GREEN=$(tput setaf 2)
RED=$(tput setaf 1)
YELLOW=$(tput setaf 3)
CYAN=$(tput setaf 6)
RESET=$(tput sgr0)

log()  { printf "%s[%s]%s %s\n" "$CYAN" "$SCRIPT_NAME" "$RESET" "$1"; }
ok()   { printf "%s✔ %s%s\n"   "$GREEN" "$1" "$RESET"; }
warn() { printf "%s⚠ %s%s\n"   "$YELLOW" "$1" "$RESET"; }
err()  { printf "%s✖ %s%s\n"   "$RED" "$1" "$RESET" >&2; }

usage() { cat <<EOF
${CYAN}${SCRIPT_NAME}${RESET} v${VERSION}
Crée un groupe, l'utilisateur Neoweb et règle les ACL d'un répertoire cible.

USAGE :
  sudo $SCRIPT_NAME [-g <groupe>] [-u <user>] [-d <dir>] [-h]

OPTIONS :
  -g  Nom du groupe      (défaut : neomnia)
  -u  Nom de l’utilisateur (défaut : Neoweb)
  -d  Répertoire cible   (défaut : /opt)
  -h  Affiche cette aide
EOF
}

# ─── Paramètres par défaut ───────────────────────────────────
GROUP="neomnia"
USER="Neoweb"
TARGET_DIR="/opt"

# ─── Parse des options CLI ───────────────────────────────────
while getopts ":g:u:d:h" opt; do
  case "$opt" in
    g) GROUP="$OPTARG" ;;
    u) USER="$OPTARG" ;;
    d) TARGET_DIR="$OPTARG" ;;
    h) usage; exit 0 ;;
    *) usage; exit 1 ;;
  esac
done

require_root() {
  [[ $EUID -eq 0 ]] || { err "Ce script doit être lancé en root/sudo."; exit 1; }
}

create_group() {
  if getent group "$GROUP" >/dev/null; then
    warn "Le groupe $GROUP existe déjà."
  else
    groupadd "$GROUP" && ok "Groupe $GROUP créé."
  fi
}

create_user() {
  if id "$USER" &>/dev/null; then
    warn "L’utilisateur $USER existe déjà."
  else
    useradd -m -g "$GROUP" "$USER" && ok "Utilisateur $USER créé et ajouté à $GROUP."
    echo "Définissez le mot de passe pour $USER :"
    passwd "$USER"
  fi
}

set_permissions() {
  if [[ -d "$TARGET_DIR" ]]; then
    chown -R :"$GROUP" "$TARGET_DIR"
    chmod -R g+rwX "$TARGET_DIR"
    setfacl -R -d -m g:"$GROUP":rwX "$TARGET_DIR"
    ok "ACL appliquées sur $TARGET_DIR pour $GROUP."
  else
    err "Le répertoire $TARGET_DIR n’existe pas."
    exit 1
  fi
}

main() {
  require_root
  create_group
  create_user
  set_permissions
  ok "Configuration terminée 🎉"
}

main "$@"
