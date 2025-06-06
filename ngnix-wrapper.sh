#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# nginx-wrapper.sh — Kickstarter for Nginx + MariaDB/MySQL
# Author: Charles VDD
# Description:
#   - Updates/upgrades the system on Debian/Ubuntu.
#   - Installs and enables Nginx instead of Apache.
#   - Installs, secures MariaDB/MySQL, then creates a database + user named after the VPS user.
#   - Configures Nginx to serve from /opt/www/<username>.
#   - Applies recursive ownership and permissions under /opt/www.
# ------------------------------------------------------------------------------

set -e  # Exit immediately if any command fails
trap 'echo "[Error] Line $LINENO failed. Aborting."; exit 1' ERR

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'  # No color

echo -e "${GREEN}=== Starting Nginx + MariaDB/MySQL Kickstarter ===${NC}"

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

# 5. Install Nginx
echo -e "${GREEN}→ Installing Nginx...${NC}"
apt install nginx -y
if systemctl is-active --quiet nginx; then
  echo -e "${GREEN}→ Nginx installed and running.${NC}"
  systemctl enable nginx
else
  echo -e "${RED}[ERROR] Nginx installation failed.${NC}"
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
echo -e "${GREEN}→ Securing MariaDB (mysql_secure_installation)...${NC}"
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

# 9. Deploy Nginx server block to serve from /opt/www/${VPS_USER}
echo -e "${GREEN}→ Deploying Nginx server block (root: /opt/www/${VPS_USER})...${NC}"

WEB_ROOT="/opt/www/${VPS_USER}"
mkdir -p "${WEB_ROOT}"

# 10. Apply recursive ownership and permissions under /opt/www
#     - Ownership: ${VPS_USER}:${VPS_USER}
#     - Permissions: 755 (rwx for owner, rx for group/others)
echo -e "${GREEN}→ Applying ownership and permissions under /opt/www...${NC}"
chown -R "${VPS_USER}:${VPS_USER}" "/opt/www"
chmod -R 755 "/opt/www"
echo -e "${GREEN}→ Ownership and permissions set.${NC}"

# 11. Create or overwrite the default Nginx site configuration
NGINX_CONF="/etc/nginx/sites-available/${VPS_USER}.conf"
echo -e "${GREEN}→ Creating Nginx configuration at ${NGINX_CONF}...${NC}"
cat <<EOF > "${NGINX_CONF}"
server {
    listen 80;
    listen [::]:80;

    server_name _;  # Replace with your domain if you have one

    root ${WEB_ROOT};
    index index.html index.htm index.php;

    location / {
        try_files \$uri \$uri/ =404;
    }

    # PHP processing (uncomment if you want PHP support)
    #location ~ \.php\$ {
    #    include snippets/fastcgi-php.conf;
    #    fastcgi_pass unix:/run/php/php7.4-fpm.sock;
    #}

    error_log /var/log/nginx/${VPS_USER}_error.log;
    access_log /var/log/nginx/${VPS_USER}_access.log;
}

EOF

# 12. Enable this site, disable default, and reload Nginx
echo -e "${GREEN}→ Enabling site '${VPS_USER}' and reloading Nginx...${NC}"
ln -sf "${NGINX_CONF}" /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t >/dev/null
systemctl reload nginx
echo -e "${GREEN}→ Nginx server block is active.${NC}"

echo -e "${GREEN}=== Installation Complete! Your site is now live at /opt/www/${VPS_USER} ===${NC}"
exit 0
