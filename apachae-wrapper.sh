#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# install.sh — Kickstarter Apache + SQL
# ------------------------------------------------------------------------------

set -e   # Arrêt à la première erreur
trap 'echo "[Erreur] Ligne $LINENO échouée. Arrêt du script."; exit 1' ERR

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # Pas de couleur

echo -e "${GREEN}=== Démarrage du kickstarter Apache + SQL ===${NC}"

# 1. Vérifier les droits root
if [ "$(id -u)" -ne 0 ]; then
  echo -e "${RED}[ERREUR] Ce script doit être exécuté en root.${NC}"
  exit 1
fi
echo -e "${GREEN}→ Exécuté en root : OK${NC}"

# 2. Mise à jour du système
echo -e "${GREEN}→ Mise à jour des paquets...${NC}"
apt update && apt upgrade -y
echo -e "${GREEN}→ Mise à jour terminée.${NC}"

# 3. Installation d'Apache
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

# 4. Installation de MariaDB (ou MySQL)
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

# 5. Sécuriser MariaDB
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

# 6. Importer le script SQL (création de la BD & utilisateur)
echo -e "${GREEN}→ Création de la base et utilisateur SQL...${NC}"
mysql < ./sql-setup/create_database.sql
echo -e "${GREEN}→ Base de données créée.${NC}"

# 7. Déploiement de la config Apache
echo -e "${GREEN}→ Déploiement de la configuration Apache...${NC}"
cp ./apache-config/000-default.conf /etc/apache2/sites-available/000-default.conf

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
