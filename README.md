# 🖥️ Install “init.ssh” Script via RAW GitHub

This README explains how to fetch and execute the `init.ssh` script in one command directly from GitHub. The goal is to quickly prepare an Ubuntu server (VPS) by automating:

- System update
- Installation of essential packages
- Basic firewall (UFW) configuration

> **Note**: The previous version attempted to create an “admins” group and adjust permissions in `/etc` and `/opt`, which could break `sudo`. This version removes all group‐creation steps.

---

## 🚀 Execution Command

Open a terminal on your machine (or your VPS) and paste:

```bash
curl -fsSL https://raw.githubusercontent.com/charlesvdd/administrator-neomnia/init/init.ssh | sudo bash
