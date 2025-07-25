
# 🖥️ Install “init.ssh” Script via RAW GitHub - Version 1.0.1201

This README explains how to fetch and execute the `init.ssh` script in one command directly from GitHub. The goal is to quickly prepare an Ubuntu server (VPS) by automating:
- System update
- Installation of essential packages
- Basic firewall (UFW) configuration

> **Note**: The previous version attempted to create an “admins” group and adjust permissions in `/etc` and `/opt`, which could break `sudo`. This version removes all group-creation steps.

## Version History
- **1.0.1201**: Initial release of the script with basic setup functionalities.

## 🚀 Execution Command
Open a terminal on your machine (or your VPS) and paste:
```bash
curl -fsSL -o init.ssh https://raw.githubusercontent.com/charlesvdd/administrator-neomnia/init/init.ssh
chmod +x init.ssh
sudo ./init.ssh
```
