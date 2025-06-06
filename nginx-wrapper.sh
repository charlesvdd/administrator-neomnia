#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# nginx-wrapper.sh — Kickstarter pour Nginx + MariaDB/MySQL
# Auteur : Charles VDD
# Description :
#   - Met à jour le système Debian/Ubuntu.
#   - Installe et démarre Nginx (en gérant le cas “qemu” sans planter).
#   - Installe, sécurise MariaDB/MySQL, puis crée une base + un utilisateur portant le nom de l’utilisateur VPS.
#   - Configure Nginx pour servir depuis /opt/www/<votre_login>.
#   - Applique récursivement les droits sous /opt/www.
#   - Lance ensuite le navigateur par défaut vers l’URL racine du site.
# ------------------------------------------------------------------------------

set -e  # Arrêt immédiat si une commande renvoie un code ≠ 0
trap 'echo "[Erreur] Ligne $LINENO échouée. Arrêt du script."; exit 1' ERR

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'  # Pas de couleur

echo -e "${GREEN}=== Démarrage du kickstarter Nginx + MariaDB/MySQL ===${NC}"

# 1. Vérifier qu’on est root
if [ "$(id -u)" -ne 0 ]; then
  echo -e "${RED}[ERREUR] Ce script doit être exécuté en root (sudo).${NC}"
  exit 1
fi
echo -e "${GREEN}→ Exécution en root : OK${NC}"

# 2. Détecter l’utilisateur VPS (celui qui a lancé sudo)
if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
  VPS_USER="$SUDO_USER"
else
  VPS_USER="$(whoami)"
fi
echo -e "${GREEN}→ Utilisateur VPS détecté : ${VPS_USER}${NC}"

# 3. Demander le mot de passe pour l’utilisateur SQL (saisi masqué)
echo -e "${GREEN}→ Saisissez le mot de passe pour l’utilisateur MariaDB/MySQL '${VPS_USER}' :${NC}"
read -s SQL_PASS
echo
if [ -z "$SQL_PASS" ]; then
  echo -e "${RED}[ERREUR] Le mot de passe ne peut pas être vide.${NC}"
  exit 1
fi

# 4. Mise à jour du système
echo -e "${GREEN}→ Mise à jour des paquets et upgrade...${NC}"
apt update && apt upgrade -y
echo -e "${GREEN}→ Mise à jour terminée.${NC}"

# 5. Installation de Nginx
echo -e "${GREEN}→ Installation de Nginx...${NC}"
if apt install nginx -y; then
  echo -e "${GREEN}→ Nginx installé avec succès.${NC}"
  systemctl enable nginx
  systemctl start nginx
  # On vérifie que le service tourne bien
  if systemctl is-active --quiet nginx; then
    echo -e "${GREEN}→ Nginx est en cours d’exécution.${NC}"
  else
    echo -e "${RED}[ERREUR] Nginx installé mais le service ne tourne pas.${NC}"
    exit 1
  fi
else
  echo -e "${RED}[ERREUR] L’installation de Nginx a échoué.${NC}"
  exit 1
fi

# 6. Installation de MariaDB (ou MySQL)
echo -e "${GREEN}→ Installation de MariaDB...${NC}"
if apt install mariadb-server -y; then
  echo -e "${GREEN}→ MariaDB installé avec succès.${NC}"
  systemctl enable mariadb
  systemctl start mariadb
  if systemctl is-active --quiet mariadb; then
    echo -e "${GREEN}→ MariaDB est en cours d’exécution.${NC}"
  else
    echo -e "${RED}[ERREUR] MariaDB installé mais le service ne tourne pas.${NC}"
    exit 1
  fi
else
  echo -e "${RED}[ERREUR] L’installation de MariaDB a échoué.${NC}"
  exit 1
fi

# 7. Sécurisation de MariaDB
echo -e "${GREEN}→ Sécurisation de MariaDB (mysql_secure_installation)...${NC}"
mysql_secure_installation <<EOF

Y
root_password_placeholder
root_password_placeholder
Y
Y
Y
Y
EOF
echo -e "${GREEN}→ MariaDB sécurisé.${NC}"

# 8. Création de la base et de l’utilisateur SQL
DB_NAME="${VPS_USER}"
SQL_USER="${VPS_USER}"
echo -e "${GREEN}→ Création de la base '${DB_NAME}' et de l’utilisateur SQL '${SQL_USER}'...${NC}"
mysql <<EOF
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${SQL_USER}'@'localhost' IDENTIFIED BY '${SQL_PASS}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${SQL_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF
echo -e "${GREEN}→ Base '${DB_NAME}' et utilisateur '${SQL_USER}' créés.${NC}"

# 9. Déploiement de la configuration Nginx (racine : /opt/www/${VPS_USER})
echo -e "${GREEN}→ Déploiement du server block Nginx (root : /opt/www/${VPS_USER})...${NC}"

WEB_ROOT="/opt/www/${VPS_USER}"
mkdir -p "${WEB_ROOT}"

# 10. Appliquer les droits récursifs sous /opt/www
echo -e "${GREEN}→ Application des droits sous /opt/www...${NC}"
chown -R "${VPS_USER}:${VPS_USER}" "/opt/www"
chmod -R 755 "/opt/www"
echo -e "${GREEN}→ Droits appliqués sous /opt/www.${NC}"

# 11. Création du fichier de configuration Nginx pour ce site
NGINX_CONF="/etc/nginx/sites-available/${VPS_USER}.conf"
echo -e "${GREEN}→ Création de ${NGINX_CONF}...${NC}"
cat <<EOF > "${NGINX_CONF}"
server {
    listen 80;
    listen [::]:80;

    server_name _;  # Remplacez par votre nom de domaine si besoin

    root ${WEB_ROOT};
    index index.html index.htm index.php;

    location / {
        try_files \$uri \$uri/ =404;
    }

    # Si vous souhaitez activer PHP, décommentez le bloc suivant et 
    # installez php-fpm (ex. php7.4-fpm)
    #location ~ \.php\$ {
    #    include snippets/fastcg
