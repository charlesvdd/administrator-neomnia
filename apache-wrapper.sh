#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# apache-wrapper.sh — Kickstarter for Apache + MariaDB/MySQL
# Author: Charles VDD
# Description: 
#   - Installs Apache2 and MariaDB/MySQL on a Debian/Ubuntu VPS.
#   - Secures the database, creates a database + user named after the VPS user.
#   - Sets up a VirtualHost pointing to /opt/www/<username>.
#   - Applies correct ownership and permissions recursively under /opt/www.
# ------------------------------------------------------------------------------

set -e  # Exit immediately if any command fails
trap 'echo "[Error] Line $LINENO failed. Aborting."; exit 1' ERR

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'  # No color

echo -e "${GREEN}=== Starting Apache + MariaDB/MySQL Kickstarter ===${NC}"

# 1. Verify root privileges
if [ "$(id -u)" -ne 0 ]; then
  echo -e "${RED}[ERROR] This script must be run as root (use sudo).${NC}"
  exit 1
fi
echo -e "${GREEN}→ Running as root: OK${NC}"

# 2. Detect VPS user (the one who invoked sudo)
if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
  VPS_USER="$SUDO_USER"
else
  VPS_USER="$(whoami)"
fi
echo -e "${GREEN}→ VPS user detected: ${VPS_USER}${NC}"

# 3. Prompt for the SQL user’s password (hidden entry)
echo -e "${GREEN}→ Enter the password for the MariaDB/MySQL user '${VPS_USER}':${NC}"
read -s SQL_PASS
echo
if [ -z "$SQL_PASS" ]; then
  echo -e "${RED}[ERROR] Password cannot be empty.${NC}"
  exit 1
fi

# 4. System update
echo -e "${GREEN}→ Updating package lists and upgrading existing packages...${NC}"
apt update && apt upgrade -y
echo -e "${GREEN}→ System update completed.${NC}"

# 5. Install Apache2
echo -e "${GREEN}→ Installing Apache2...${NC}"
apt install apache2 -y
if systemctl is-active --quiet apache2; then
  echo -e "${GREEN}→ Apache2 installed and running.${NC}"
  systemctl enable apache2
else
  echo -e "${RED}[ERROR] Apache2 installation failed.${NC}"
  exit 1
fi

# 6. Install MariaDB (or MySQL)
echo -e "${GREEN}→ Installing MariaDB server...${NC}"
apt install mariadb-server -y
if systemctl is-active --quiet mariadb; then
  echo -e "${GREEN}→ MariaDB installed and running.${NC}"
  systemctl enable mariadb
else
  echo -e "${RED}[ERROR] MariaDB installation failed.${NC}"
  exit 1
fi

# 7. Secure MariaDB installation
echo -e "${GREEN}→ Securing MariaDB installation (mysql_secure_installation)...${NC}"
mysql_secure_installation <<EOF

Y
root_password_placeholder
root_password_placeholder
Y
Y
Y
Y
EOF
echo -e "${GREEN}→ MariaDB secured.${NC}"

# 8. Create database and user matching VPS_USER
DB_NAME="${VPS_USER}"
SQL_USER="${VPS_USER}"
echo -e "${GREEN}→ Creating database '${DB_NAME}' and user '${SQL_USER}'...${NC}"
mysql <<EOF
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${SQL_USER}'@'localhost' IDENTIFIED BY '${SQL_PASS}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${SQL_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF
echo -e "${GREEN}→ Database '${DB_NAME}' and user '${SQL_USER}' created.${NC}"

# 9. Deploy Apache VirtualHost to serve from /opt/www/${VPS_USER}
echo -e "${GREEN}→ Deploying Apache VirtualHost (root: /opt/www/${VPS_USER})...${NC}"

WEB_ROOT="/opt/www/${VPS_USER}"

# Create the target directory
mkdir -p "${WEB_ROOT}"

# 10. Apply recursive ownership and permissions under /opt/www
#    - Ownership: ${VPS_USER}:${VPS_USER}
#    - Permissions: 755 (rwx for owner, rx for group/others)
echo -e "${GREEN}→ Applying ownership and permissions under /opt/www...${NC}"
chown -R "${VPS_USER}:${VPS_USER}" "/opt/www"
chmod -R 755 "/opt/www"
echo -e "${GREEN}→ Ownership and permissions set.${NC}"

# 11. Create or overwrite the default site configuration
cat <<EOF >/etc/apache2/sites-available/000-default.conf
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot ${WEB_ROOT}

    <Directory ${WEB_ROOT}>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/${VPS_USER}_error.log
    CustomLog \${APACHE_LOG_DIR}/${VPS_USER}_access.log combined
</VirtualHost>
EOF

# 12. Enable site, disable default if necessary, and reload Apache
echo -e "${GREEN}→ Enabling site and reloading Apache...${NC}"
a2dissite 000-default.conf >/dev/null 2>&1 || true
a2ensite 000-default.conf >/dev/null
apache2ctl configtest >/dev/null 2>&1
systemctl reload apache2
echo -e "${GREEN}→ Apache VirtualHost is active.${NC}"

echo -e "${GREEN}=== Installation Complete! Your site is now live at /opt/www/${VPS_USER} ===${NC}"
exit 0
