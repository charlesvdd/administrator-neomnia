# 🛠️ Basic Ubuntu Setup Script

<div align="center">
  <img src="https://img.shields.io/badge/Linux-Ubuntu-orange" alt="Ubuntu Badge">
  <img src="https://img.shields.io/badge/Security-Firewall-blue" alt="UFW Badge">
  <img src="https://img.shields.io/badge/Shell-Bash-informational" alt="Bash Badge">
</div>

---

## 🎯 Purpose

This script helps you **quickly prepare a fresh Ubuntu VPS** by:
- Updating system packages.
- Installing essential utilities (`tree`, `ufw`, `git`, `curl`, `wget`).
- Enabling and configuring a basic firewall with UFW.
- Creating an `admins` group and granting it read/write access to `/etc` and `/opt`.
- Adding the current user to the `admins` group.

---

## 📋 Features

1. **System Update & Upgrade**  
   - Ensures the OS is up to date with the latest security patches.

2. **Essential Packages Installation**  
   - Installs commonly used tools:  
     - `tree` (directory listing in tree format)  
     - `ufw` (Uncomplicated Firewall)  
     - `git`, `curl`, `wget` (version control and download tools)

3. **Basic Firewall Configuration**  
   - Enables UFW and allows SSH traffic only (port 22).

4. **‘admins’ Group & Permissions**  
   - Creates an `admins` group (if not already present).  
   - Changes ownership of `/etc` and `/opt` to `root:admins`.  
   - Grants read/write permissions to the group.  
   - Adds your user account to the `admins` group.

---

## 🚀 Usage

1. **Clone the repository and switch to the `init` branch**:

   ```bash
   git clone https://github.com/charlesvdd/administrator-neomnia.git
   cd administrator-neomnia
   git checkout init
