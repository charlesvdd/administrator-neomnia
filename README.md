# Kickstarter: Nginx + MariaDB/MySQL Setup

**Author:** Charles VDD  
**Last updated:** June 2025

This **kickstarter** automates the process of setting up an Nginx web server and MariaDB/MySQL database on a Debian/Ubuntu VPS.  
It will:

1. Update and upgrade the system.
2. Install and enable Nginx.
3. Install and enable MariaDB (or MySQL).
4. Secure the database with `mysql_secure_installation`.
5. Create a database and a matching user using your VPS username.
6. Configure Nginx to serve content from `/opt/www/<your_username>`.
7. Apply correct ownership and recursive permissions under `/opt/www`.

---

## Quick One-Line Installation

To run everything from GitHub in one shot, simply execute:

```bash
curl -sSL https://raw.githubusercontent.com/charlesvdd/administrator-neomnia/apache-wrapper/nginx-wrapper.sh \
  -o /tmp/nginx-wrapper.sh \
  && chmod +x /tmp/nginx-wrapper.sh \
  && sudo /tmp/nginx-wrapper.sh
