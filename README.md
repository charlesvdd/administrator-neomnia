#!/usr/bin/env bash
# File: next-project
# Purpose: Installer un projet Next.js sous /opt/<projet> avec nvm/Node/Next sélectionnables,
#          permissions setgid + ACL, logs préfixés [ NEOMNIA ].
set -euo pipefail

############################################################
# Helpers
############################################################
PREFIX="[ NEOMNIA ]"

log() { printf "%s %s\n" "$PREFIX" "$*" >&2; }
die() { printf "%s ERROR: %s\n" "$PREFIX" "$*" >&2; exit 1; }

cmd_exists() { command -v "$1" >/dev/null 2>&1; }

need_root() {
  if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    die "Ce script requiert root. Relance avec sudo."
  fi
}

ask() {
  # $1 prompt, echo reply to stdout
  local reply
  read -r -p "$1" reply
  printf "%s" "$reply"
}

confirm() {
  # returns 0 if yes, else 1
  local prompt="${1:-Confirmer ? [yes/no] }"
  local ans
  read -r -p "$prompt" ans
  case "$ans" in
    y|Y|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

normalize_kebab() {
  # stdin -> stdout kebab-case (letters/digits/-), trim dups, lowercase
  tr '[:upper:]' '[:lower:]' \
  | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-{2,}/-/g'
}

semver_to_int() {
  # "MAJOR.MINOR.PATCH" -> integer for compare (MMajor*1e6 + Minor*1e3 + Patch)
  # Missing parts treated as 0
  local s="${1:-0.0.0}"
  local major minor patch
  IFS='.' read -r major minor patch <<<"$s"
  major="${major:-0}"; minor="${minor:-0}"; patch="${patch:-0}"
  printf "%d\n" "$((major*1000000 + minor*1000 + patch))"
}

require_min_node() {
  local min="20.9.0"
  cmd_exists node || die "Node introuvable et option 'skip' sélectionnée. Choisis une installation via nvm."
  local ver
  ver="$(node -v 2>/dev/null | sed -E 's/^v//')"
  [ -n "$ver" ] || die "Impossible de déterminer la version de Node."
  local have need
  have="$(semver_to_int "$ver")"
  need="$(semver_to_int "$min")"
  if [ "$have" -lt "$need" ]; then
    die "Version Node trop basse ($ver < $min). Relance et choisis LTS ou 25.x."
  fi
  cmd_exists npx || die "npx absent. Relance et installe via nvm."
  log "Node existant validé: v$ver (>= $min)"
}

ensure_nvm() {
  if ! cmd_exists bash; then die "bash requis."; fi
  if [ -d "/root/.nvm" ]; then
    export NVM_DIR="/root/.nvm"
  elif [ -n "${SUDO_USER:-}" ] && [ -d "/home/$SUDO_USER/.nvm" ]; then
    export NVM_DIR="/home/$SUDO_USER/.nvm"
  else
    export NVM_DIR="${HOME}/.nvm"
  fi

  if [ ! -s "$NVM_DIR/nvm.sh" ]; then
    log "Installation de nvm (absent)…"
    local install_url="https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh"
    if cmd_exists curl; then
      bash -c "curl -fsSL '$install_url' | bash"
    elif cmd_exists wget; then
      bash -c "wget -qO- '$install_url' | bash"
    else
      die "curl ou wget requis pour installer nvm."
    fi
  fi

  # shellcheck disable=SC1090
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
  # shellcheck disable=SC1090
  [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
  command -v nvm >/dev/null 2>&1 || die "nvm non disponible après installation."
}

install_use_node_with_nvm() {
  # $1 strategy: lts | node25 | exact:<ver>
  local strategy="${1:-lts}"
  ensure_nvm

  case "$strategy" in
    lts)
      log "Installation/activation Node LTS via nvm…"
      nvm install --lts >/dev/null
      nvm use --lts >/dev/null
      ;;
    node25)
      log "Installation/activation Node 25.x via nvm…"
      nvm install 25 >/dev/null
      nvm use 25 >/div/null 2>&1 || nvm use 25 >/dev/null
      ;;
    exact:*)
      local v="${strategy#exact:}"
      [ -n "$v" ] || die "Version Node précise vide."
      log "Installation/activation Node $v via nvm…"
      nvm install "$v" >/dev/null
      nvm use "$v" >/devnull 2>&1 || nvm use "$v" >/dev/null
      ;;
    *)
      die "Stratégie Node inconnue: $strategy"
      ;;
  esac

  # Ensure npm/npx in PATH for this shell
  local current="$(node -v | sed 's/^v//')"
  log "Node actif: v${current}"
  command -v npx >/dev/null || die "npx introuvable après installation Node."
}

apply_permissions() {
  local path="$1" group="$2"
  chown -R "root:$group" "$path"
  chmod 2775 "$path"
  find "$path" -type d -print0 | xargs -0 chmod g+rwx
  find "$path" -type f -print0 | xargs -0 chmod g+rw

  if cmd_exists setfacl; then
    setfacl -R -m "g:${group}:rwX" "$path" || true
    setfacl -dR -m "g:${group}:rwX" "$path" || true
    log "ACL appliquées pour le groupe '${group}'."
  else
    log "setfacl absent, ACL non appliquées (chmod/setgid en place)."
  fi
}

create_group_if_needed() {
  local group="$1"
  if getent group "$group" >/dev/null 2>&1; then
    log "Groupe '${group}' existe déjà, réutilisation."
  else
    log "Création du groupe '${group}'…"
    groupadd "$group"
  fi
}

scaffold_next_app() {
  local dir="$1"
  # Crée avec options non-interactives (App Router, TS, Tailwind, ESLint, Turbopack)
  # --yes pour bypass prompts, --no-src-dir par défaut App Router gère /app
  npx --yes create-next-app@latest "$dir" \
    --typescript \
    --tailwind \
    --eslint \
    --app \
    --turbo \
    --no-install \
    --use-npm \
    --yes
}

pin_next_version_if_requested() {
  local dir="$1" next_ver="$2"
  [ -z "$next_ver" ] && return 0
  ( cd "$dir" && npm i -E "next@${next_ver}" )
  log "Next épinglé à ${next_ver}."
}

write_nvmrc_if_available() {
  local dir="$1"
  if cmd_exists node; then
    local v
    v="$(node -v)"
    echo "${v#v}" > "${dir}/.nvmrc"
    log ".nvmrc écrit (${v})."
  fi
}

############################################################
# Main
############################################################
need_root

log "Bienvenue dans l’installateur Next.js — NEOMNIA ACSS."
log "Aucune valeur par défaut cachée : rien n’est créé sans confirmation."

# 1) Demander le nom du projet (obligatoire)
project_input="$(ask "Nom du projet (kebab-case, ex: mon-app) : ")"
project_normalized="$(printf "%s" "$project_input" | normalize_kebab)"
[ -n "$project_normalized" ] || die "Nom de projet vide ou invalide."

PROJECT_NAME="$project_normalized"
PROJECT_DIR="/opt/${PROJECT_NAME}"
GROUP_NAME="$PROJECT_NAME"

log "Projet       : ${PROJECT_NAME}"
log "Chemin       : ${PROJECT_DIR}"
log "Groupe unix  : ${GROUP_NAME}"

# Confirmer avant la moindre création
if ! confirm "Créer le groupe '${GROUP_NAME}' et ${PROJECT_DIR} ? [yes/no] "; then
  die "Opération annulée par l’utilisateur."
fi

# 2) Choix Node
log "Sélection de la version de Node (via nvm):"
echo "  [1] latest-lts (recommandé)"
echo "  [2] 25.x (proposé)"
echo "  [3] version précise (ex: 25.3.0, 22.11.0)"
echo "  [4] skip (utiliser Node existant, exige >= 20.9 + npx)"
choice="$(ask "Ton choix [1-4] : ")"

NODE_STRATEGY=""
case "$choice" in
  1|"") NODE_STRATEGY="lts" ;;
  2)     NODE_STRATEGY="node25" ;;
  3)
    exact_ver="$(ask "Version exacte de Node (ex: 25.3.0) : ")"
    exact_ver="$(printf "%s" "$exact_ver" | tr -d '[:space:]')"
    [ -n "$exact_ver" ] || die "Version Node vide."
    NODE_STRATEGY="exact:${exact_ver}"
    ;;
  4)     NODE_STRATEGY="skip" ;;
  *)     die "Choix invalide." ;;
esac

# 3) Choix Next
echo "Next.js version:"
echo "  [1] latest"
echo "  [2] version précise (ex: 16.1.3)"
nchoice="$(ask "Ton choix [1-2] : ")"
NEXT_VERSION_PIN=""
case "$nchoice" in
  1|"") NEXT_VERSION_PIN="" ;;
  2)
    nver="$(ask "Version exacte de Next (ex: 16.1.3) : ")"
    nver="$(printf "%s" "$nver" | tr -d '[:space:]')"
    [ -n "$nver" ] || die "Version Next vide."
    NEXT_VERSION_PIN="$nver"
    ;;
  *) die "Choix invalide." ;;
esac

# 4) Installer/valider Node
if [ "$NODE_STRATEGY" = "skip" ]; then
  require_min_node
else
  install_use_node_with_nvm "$NODE_STRATEGY"
fi

# 5) Groupe + dossier
create_group_if_needed "$GROUP_NAME"

if [ -e "$PROJECT_DIR" ]; then
  die "Le dossier ${PROJECT_DIR} existe déjà. Abandon pour éviter l’écrasement."
fi

log "Création de ${PROJECT_DIR}…"
mkdir -p "$PROJECT_DIR"
chown "root:${GROUP_NAME}" "$PROJECT_DIR"
chmod 2775 "$PROJECT_DIR"

# 6) Scaffold Next app
log "Scaffold du projet Next.js…"
scaffold_next_app "$PROJECT_DIR"

# 7) Installation des dépendances
log "Installation des dépendances npm…"
( cd "$PROJECT_DIR" && npm install )

# 8) Pin éventuel de Next
pin_next_version_if_requested "$PROJECT_DIR" "$NEXT_VERSION_PIN"

# 9) Permissions + ACL
apply_permissions "$PROJECT_DIR" "$GROUP_NAME"

# 10) .nvmrc si Node issu de nvm
if [ "$NODE_STRATEGY" != "skip" ]; then
  write_nvmrc_if_available "$PROJECT_DIR"
fi

log "Installation terminée."
cat <<EOF

${PREFIX} RÉCAPITULATIF
- Projet      : ${PROJECT_NAME}
- Dossier     : ${PROJECT_DIR}
- Groupe      : ${GROUP_NAME}
- Node        : $(node -v 2>/dev/null || echo "non disponible")
- Next pin    : ${NEXT_VERSION_PIN:-(latest)}

Commandes utiles:
  sudo usermod -aG ${GROUP_NAME} <user>  # reconnecter la session ensuite
  cd ${PROJECT_DIR}
  npm run dev
  npm run build && npm run start -- -p 3000

Désinstallation:
  sudo systemctl stop <service> 2>/dev/null || true
  sudo rm -rf ${PROJECT_DIR}
  sudo groupdel ${GROUP_NAME} 2>/dev/null || true

EOF
