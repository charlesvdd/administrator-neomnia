
# 🖥️ Install “init.ssh” Script via RAW GitHub

## Overview
This script automates the initial setup of an Ubuntu server (VPS) by performing essential tasks such as updating the system, installing necessary packages, and configuring a basic firewall. It is designed to be fetched and executed directly from GitHub for quick and easy deployment.

## Features
- **System Update**: Ensures your system is up-to-date with the latest packages.
- **Essential Packages Installation**: Installs commonly required packages for server management.
- **UFW Configuration**: Sets up a basic firewall to allow OpenSSH and enhance server security.

> **Note**: Previous versions included steps to create an “admins” group and adjust permissions in `/etc` and `/opt`, which could potentially break `sudo`. These steps have been removed in this version to ensure system stability.

## Version History
| Version | Description |
|---------|-------------|
| 1.0.1201 | Initial release with basic setup functionalities including system update, essential package installation, and UFW configuration. |

## 🚀 Execution Command
To quickly set up your Ubuntu server, open a terminal on your machine (or your VPS) and run the following commands:

```bash
curl -fsSL -o init.ssh https://raw.githubusercontent.com/charlesvdd/administrator-neomnia/init/init.ssh
chmod +x init.ssh
sudo ./init.ssh
```

## Script Details
The script performs the following steps:
1. **Fetching the Script**: Downloads the `init.ssh` script directly from GitHub.
2. **Setting Permissions**: Makes the script executable.
3. **Running the Script**: Executes the script with root privileges to perform system setup tasks.

## Requirements
- Ubuntu operating system
- Internet connection to fetch the script and install packages
- Root or sudo access

## Notes
- Ensure you have a backup of any critical data before running setup scripts.
- This script is intended for use on a fresh installation of Ubuntu to avoid conflicts with existing configurations.
