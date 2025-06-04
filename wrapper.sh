#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# install_github_cli.sh
#
# Ce script installe GitHub CLI sur Linux, de façon « clé en main » :
#  - Auto-élévation en root si nécessaire (un seul prompt sudo, ou aucun sur Azure)
#  - Demande interactive du nom d’utilisateur GitHub et du token CLI
#  - Vérification de la validité du token (HTTP 200)
#  - Encodage du token en base64 et stockage dans ~/.config/github/credentials
#  - Installation de GitHub CLI (gh) selon la distribution
#  - Configuration de gh auth pour l’utilisateur final (pas en root)
#  - Pas de redemande de mot de passe après l’auto-élévation
#
# Usage (en une seule ligne) :
#   curl -sSL https://<votre_url>/install_github_cli.sh | bash
#
# Ou, si vous préférez récupérer d’abord le fichier :
#   curl -sSL https://<votre_url>/install_github_cli.sh -o /tmp/install_github_cli.sh
#   chmod +x /tmp/install_github_cli.sh
#   /tmp/install_github_cli.sh
#
# -----------------------------------------------------------------------------

# 1) AUTO-ÉLÉVATION : si on n’est pas root, on relance tout le script sous sudo
if [ "$(id -u)" -ne 0 ]; then
  echo "→ Passage en root (sudo)…"
  exec sudo bash -s "$@"
fi
# À partir d’ici, on est root

# 2) Détermination de l’utilisateur « réel » qui a lancé le script (pour stocker le token)
REAL_USER="${SUDO_USER:-$(id -un)}"
USER_HOME="$(eval echo "~$REAL_USER")"
# Crée éventuellement le répertoire de configuration pour l’utilisateur réel
CONFIG_DIR="$USER_HOME/.config/github"

# 3) Fonction d’affichage des étapes
print_step() {
  local msg="$1"; shift
  printf "› %s … " "$msg"
  "$@" >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    printf "OK\n"
  else
    printf "ÉCHEC\n"
    exit 1
  fi
}

# 4) Demande interactive du nom d’utilisateur GitHub + token CLI
while true; do
  read -p "Entrez votre nom d'utilisateur GitHub : " GITHUB_USER
  read -s -p "Entrez votre token GitHub CLI (token privé) : " GITHUB_TOKEN
  echo

  HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: token ${GITHUB_TOKEN}" \
    https://api.github.com/user)

  if [ "$HTTP_STATUS" -eq 200 ]; then
    echo "✔️  Token valide."
    break
  else
    echo "❌  Token invalide (HTTP $HTTP_STATUS). Veuillez réessayer."
  fi
done

# 5) Encodage du token en base64
GITHUB_TOKEN_B64="$(printf "%s" "$GITHUB_TOKEN" | base64 -w 0)"

# 6) Création du répertoire de configuration (~/.config/github) en tant que REAL_USER
print_step "Création du répertoire $CONFIG_DIR pour $REAL_USER" \
  bash -c "mkdir -p \"$CONFIG_DIR\" && chown \"$REAL_USER\":\"$REAL_USER\" \"$CONFIG_DIR\""

# 7) Stockage des identifiants dans ~/.config/github/credentials
CREDENTIALS_FILE="$CONFIG_DIR/credentials"
print_step "Enregistrement des identifiants dans $CREDENTIALS_FILE" \
  bash -c "printf 'username=%s\n' \"$GITHUB_USER\" > \"$CREDENTIALS_FILE\" && \
           printf 'token_base64=%s\n' \"$GITHUB_TOKEN_B64\" >> \"$CREDENTIALS_FILE\" && \
           chown \"$REAL_USER\":\"$REAL_USER\" \"$CREDENTIALS_FILE\" && chmod 600 \"$CREDENTIALS_FILE\""

# 8) Détection de la distribution pour installer GitHub CLI (gh)
if [ -r /etc/os-release ]; then
  . /etc/os-release
  DISTRO_ID="$ID"
  DISTRO_FAMILY="$ID_LIKE"
else
  DISTRO_ID="unknown"
  DISTRO_FAMILY="unknown"
fi

install_gh_debian() {
  print_step "Mise à jour APT"      apt-get update -y
  print_step "Installation de gh"   apt-get install -y gh
}

install_gh_fedora() {
  print_step "Installation de gh"   dnf install -y gh
}

install_gh_arch() {
  print_step "Installation de gh"   pacman -Sy --noconfirm gh
}

install_gh_generic() {
  echo "⚠️  Distribution non détectée ou non supportée automatiquement."
  echo "    Installez manuellement GitHub CLI : https://github.com/cli/cli#installation"
  exit 1
}

# 9) Lancement de l’installation de gh selon la distro
case "$DISTRO_ID" in
  ubuntu|debian)
    install_gh_debian
    ;;
  fedora)
    install_gh_fedora
    ;;
  arch)
    install_gh_arch
    ;;
  *)
    if echo "$DISTRO_FAMILY" | grep -q "debian"; then
      install_gh_debian
    else
      install_gh_generic
    fi
    ;;
esac

# 10) Configuration de GitHub CLI pour l’utilisateur réel
#     On place le token en stdin pour gh auth login --with-token,
#     en exécutant la commande sous $REAL_USER, afin que la config soit dans leur home.
print_step "Configuration de gh auth pour l’utilisateur $REAL_USER" \
  bash -c "printf '%s' \"$GITHUB_TOKEN\" | sudo -u \"$REAL_USER\" gh auth login --with-token"

# 11) Message de fin
echo
echo "🎉 GitHub CLI a été installé et configuré pour l’utilisateur $REAL_USER."
echo "    Les informations sont stockées dans : $CREDENTIALS_FILE"
exit 0
