#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# apache-wrapper.sh — Kickstarter Apache + SQL (SQL dynamique selon l’utilisateur VPS)
# ------------------------------------------------------------------------------

set -e   # Arrêt à la première erreur
trap 'echo "[Erreur] Ligne $LINENO échouée. Arrêt du script."; exit 1' ERR

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # Pas de couleur

echo -e "${GREEN}=== Démarrage du kickstarter Apache + SQL ===${NC}"

# 1. Vérifier les droits root
if [ "$(id -u)" -ne 0 ]; then
  echo -e "${RED}[ERREUR] Ce script doit être exécuté en root (via sudo).${NC}"
  exit 1
fi
echo -e "${GREEN}→ Exécuté en root : OK${NC}"

# 2. Détecter l’utilisateur VPS (créateur du script)
# SUDO_USER est défini si on passe par sudo ; sinon, on reste sur whoami (root)
if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
  VPS_USER="$SUDO_USER"
else
  VPS_USER="$(whoami)"
fi
echo -e "${GREEN}→ Nom de l’utilisateur VPS détecté : ${VPS_USER}${NC}"

# 3. Demander le mot de passe pour l’utilisateur SQL (masqué)
echo -e "${GREEN}→ Veuillez saisir le mot de passe pour l’utilisateur SQL \"${VPS_USER}\" :${NC}"
read -s SQL_PASS
echo
if [ -z "$SQL_PASS" ]; then
  echo -e "${RED}[ERREUR] Le mot de passe SQL ne peut pas être vide.${NC}"
  exit 1
fi

# 4. Mise à jour du système
echo -e "${GREEN}→ Mise à jour des paquets...${NC}"
apt update && apt upgrade -y
echo -e "${GREEN}→ Mise à jour terminée.${NC}"

# 5. Installation d'Apache
echo -e "${GREEN}→ Installation d'Apache...${NC}"
apt install apache2 -y
if systemctl status apache2 >/dev/null 2>&1; then
  echo -e "${GREEN}→ Apache installé avec succès.${NC}"
  systemctl enable apache2
  systemctl start apache2
else
  echo -e "${RED}[ERREUR] L'installation d'Apache a échoué.${NC}"
  exit 1
fi

# 6. Installation de MariaDB (ou MySQL)
echo -e "${GREEN}→ Installation de MariaDB...${NC}"
apt install mariadb-server -y
if systemctl status mariadb >/dev/null 2>&1; then
  echo -e "${GREEN}→ MariaDB installé avec succès.${NC}"
  systemctl enable mariadb
  systemctl start mariadb
else
  echo -e "${RED}[ERREUR] L'installation de MariaDB a échoué.${NC}"
  exit 1
fi

# 7. Sécuriser MariaDB
echo -e "${GREEN}→ Sécurisation de MariaDB (mysql_secure_installation)...${NC}"
mysql_secure_installation <<EOF

Y
votre_mot_de_passe_root_SQL
votre_mot_de_passe_root_SQL
Y
Y
Y
Y
EOF
echo -e "${GREEN}→ MariaDB sécurisé.${NC}"

# 8. Création de la base et de l’utilisateur SQL (SQL dynamique)
DB_NAME="${VPS_USER}"
SQL_USER="${VPS_USER}"
echo -e "${GREEN}→ Création de la base '${DB_NAME}' et de l’utilisateur SQL '${SQL_USER}'...${NC}"
mysql <<EOF
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${SQL_USER}'@'localhost' IDENTIFIED BY '${SQL_PASS}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${SQL_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF
echo -e "${GREEN}→ Base de données '${DB_NAME}' et utilisateur '${SQL_USER}' créés.${NC}"

# 9. Déploiement de la config Apache
echo -e "${GREEN}→ Déploiement de la configuration Apache…${NC}"

# Si vous avez un fichier 000-default.conf dans apache-config/, copiez-le :
if [ -f "./apache-config/000-default.conf" ]; then
  cp ./apache-config/000-default.conf /etc/apache2/sites-available/000-default.conf
else
  # Sinon, on crée un vhost basique pointant vers /home/VPS_USER/www/
  mkdir -p /home/"${VPS_USER}"/www
  chown -R "${VPS_USER}":"${VPS_USER}" /home/"${VPS_USER}"/www

  cat <<EOF >/etc/apache2/sites-available/000-default.conf
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /home/${VPS_USER}/www

    <Directory /home/${VPS_USER}/www>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/${VPS_USER}_error.log
    CustomLog \${APACHE_LOG_DIR}/${VPS_USER}_access.log combined
</VirtualHost>
EOF
fi

# Vérifier la syntaxe Apache
if apache2ctl configtest >/dev/null 2>&1; then
  echo -e "${GREEN}→ Configuration Apache valide.${NC}"
  systemctl reload apache2
else
  echo -e "${RED}[ERREUR] Vérification de la config Apache échouée.${NC}"
  exit 1
fi

echo -e "${GREEN}=== Installation terminée avec succès ! ===${NC}"
exit 0
