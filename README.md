# 🖥️ Install “init.ssh” Script via RAW GitHub

This README explains how to fetch and execute the `init.ssh` script in one command directly from GitHub. The goal is to quickly prepare an Ubuntu server (VPS) by automating the following tasks:

- System update
- Installation of essential packages
- Basic firewall (UFW) configuration
- Creation of an “admins” group and granting permissions on `/etc` and `/opt`
- Adding the current user to the “admins” group

---

## 🚀 Execution Command

Open a terminal on your machine (or your VPS) and paste the following command to run the script from the `init` branch:

```bash
curl -fsSL https://raw.githubusercontent.com/charlesvdd/administrator-neomnia/init/init.ssh | sudo bash
