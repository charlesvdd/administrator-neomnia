
#!/usr/bin/env bash
#
# wrapper.sh — présente un alias gitstart pour lancer le script gitexe.sh.
# Il gère la collecte/chiffrement des identifiants GitHub, installe la CLI if needed,
# affiche un bargraph ASCII et affiche la licence.
#

# -----------------------------------------------
# 1. Vérifier qu'on est en root
# -----------------------------------------------
if [ "$EUID" -ne 0 ]; then
  echo "Erreur : ce script doit être exécuté en root."
  exit 1
fi

# -----------------------------------------------
# 2. Configuration des chemins et clés
# -----------------------------------------------
CONFIG_DIR="/root/.config/admin-gh"
KEY_FILE="$CONFIG_DIR/secret.key"
ENC_FILE="$CONFIG_DIR/ghcreds.enc"
ALIASES_FILE="/etc/profile.d/gitstart_alias.sh"
LICENSE_FILE="/usr/local/share/admin-gh/LICENSE.txt"

mkdir -p "$CONFIG_DIR"
chmod 700 "$CONFIG_DIR"

# -----------------------------------------------
# 3. Générer une clé de chiffrement si nécessaire
# -----------------------------------------------
if [ ! -f "$KEY_FILE" ]; then
  echo "[*] Génération de la clé de chiffrement …"
  openssl rand -base64 32 > "$KEY_FILE"
  chmod 600 "$KEY_FILE"
fi

# -----------------------------------------------
# 4. Fonction pour tester les identifiants GitHub
# -----------------------------------------------
test_github_creds() {
  local user="$1"
  local token="$2"
  # On teste via l'API GitHub : /user renvoie 200 si auth OK
  local response
  response=$(curl -s -u "${user}:${token}" -o /dev/null -w "%{http_code}" https://api.github.com/user)
  if [ "$response" = "200" ]; then
    return 0
  else
    return 1
  fi
}

# -----------------------------------------------
# 5. Boucle de demande d'identifiants (username + token)
# -----------------------------------------------
while true; do
  echo "Entrez votre nom d'utilisateur GitHub :"
  read -r GH_USER
  echo "Entrez votre clé API GitHub (token, en lecture seule ou plus) :"
  read -rs GH_TOKEN
  echo

  if test_github_creds "$GH_USER" "$GH_TOKEN"; then
    echo "[OK] Identifiants valides."
    break
  else
    echo "Identifiants invalides, veuillez réessayer."
  fi
done

# -----------------------------------------------
# 6. Chiffrer et stocker les identifiants
# -----------------------------------------------
# On combine user:token dans une chaîne, puis on chiffre en AES-256-CBC, passe-file=KEY_FILE.
echo "${GH_USER}:${GH_TOKEN}" | \
  openssl enc -aes-256-cbc -salt -pass "file:${KEY_FILE}" -pbkdf2 -out "${ENC_FILE}"
chmod 600 "${ENC_FILE}"
echo "[*] Identifiants chiffrés et stockés dans ${ENC_FILE}."

# -----------------------------------------------
# 7. Installer la CLI GitHub (gh) si nécessaire
# -----------------------------------------------
install_gh_cli() {
  if command -v gh &>/dev/null; then
    echo "[*] GitHub CLI (gh) déjà installé."
    return 0
  fi

  echo "[*] GitHub CLI introuvable. Installation en cours…"

  # Détection du gestionnaire de paquets
  if command -v apt-get &>/dev/null; then
    DEBIAN_FRONTEND=noninteractive apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y gh
  elif command -v yum &>/dev/null; then
    yum install -y gh
  elif command -v dnf &>/dev/null; then
    dnf install -y gh
  else
    echo "Impossible de détecter le gestionnaire de paquets. Veuillez installer 'gh' manuellement."
    return 1
  fi

  if command -v gh &>/dev/null; then
    echo "[OK] GitHub CLI installé."
    return 0
  else
    echo "Échec de l'installation de 'gh'."
    return 1
  fi
}

install_gh_cli

# -----------------------------------------------
# 8. Création de l'alias 'gitstart'
# -----------------------------------------------
# On crée un fichier dans /etc/profile.d/ pour que l’alias soit chargé à la connexion.
cat << 'EOF' > "$ALIASES_FILE"
#!/usr/bin/env bash
# Alias pour lancer gitexe.sh
alias gitstart="/usr/local/bin/gitexe.sh"
EOF
chmod 644 "$ALIASES_FILE"
echo "[*] Alias 'gitstart' créé. Vous pouvez désormais lancer 'gitstart' depuis n'importe quel shell (reconnectez-vous si nécessaire)."

# -----------------------------------------------
# 9. Installer le script gitexe.sh dans /usr/local/bin
# -----------------------------------------------
# On suppose que gitexe.sh est dans le même dossier que wrapper.sh lors de l'appel initial.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
if [ -f "${SCRIPT_DIR}/gitexe.sh" ]; then
  cp "${SCRIPT_DIR}/gitexe.sh" /usr/local/bin/gitexe.sh
  chmod +x /usr/local/bin/gitexe.sh
  echo "[*] gitexe.sh copié dans /usr/local/bin/ et rendu exécutable."
else
  echo "Attention : gitexe.sh introuvable dans ${SCRIPT_DIR}. Veuillez le placer à cet emplacement ou modifier ce script."
fi

# -----------------------------------------------
# 10. Affichage « graphique » simple (barre ASCII)
# -----------------------------------------------
draw_bar() {
  local percent=$1
  local width=30
  local filled=$(( percent * width / 100 ))
  local empty=$(( width - filled ))
  printf "["
  for ((i=0; i<filled; i++)); do printf "="; done
  for ((i=0; i<empty; i++)); do printf " "; done
  printf "] %3d%%\n" "$percent"
}

echo
echo "Progression simulée de l’installation :"
for p in 0 20 40 60 80 100; do
  draw_bar "$p"
  sleep 0.2
done

# -----------------------------------------------
# 11. Affichage de la licence
# -----------------------------------------------
# On copie d’abord le fichier LICENSE du dépôt vers /usr/local/share/admin-gh/, puis on l’affiche.
if [ -f "${SCRIPT_DIR}/LICENSE" ]; then
  mkdir -p "$(dirname "${LICENSE_FILE}")"
  cp "${SCRIPT_DIR}/LICENSE" "${LICENSE_FILE}"
  echo
  echo "=== Contenu de la licence ==="
  cat "${LICENSE_FILE}"
  echo "=== Fin de la licence ==="
else
  echo "Aucun fichier LICENSE trouvé dans ${SCRIPT_DIR}."
fi

# -----------------------------------------------
# 12. Message final
# -----------------------------------------------
echo
echo "Installation du wrapper terminée. Utilisez désormais la commande 'gitstart' pour lancer votre installation GitHub."
exit 0
