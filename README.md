# Administrator Neomnia – Git & GitHub CLI Installation Script

**Author:** Charles van den Driessche  
**Website:** [www.neomnia.net](https://www.neomnia.net)  
**License:** GNU GPL v3.0  

---

## Table of Contents

- [Overview](#overview)  
- [Prerequisites](#prerequisites)  
- [Local Installation](#local-installation)  
- [Remote Execution via SSH + curl](#remote-execution-via-ssh--curl)  
  - [Using `--remote`](#using--remote)  
  - [One-Liner with `curl -fsS | bash`](#one-liner-with-curl--fss--bash)  
- [Manual Steps (if needed)](#manual-steps-if-needed)  
- [Script Function Breakdown](#script-function-breakdown)  
- [License](#license)

---

## Overview

This repository contains a script named `install.sh` that will:

1. **Update the system** (using `apt-get` on Linux or Homebrew on macOS).  
2. **Install Git** and the **GitHub CLI (`gh`)**.  
3. **Generate or import** an SSH key pair and automatically add it to your GitHub account via `gh`.  
4. **Configure Git** with your name and email.  
5. **Verify** the SSH connection by listing your GitHub repositories.

Additionally, the script includes a built-in function to **execute itself on a remote machine** over SSH, using `curl -fsS` to fetch the script directly from GitHub, so you don’t have to clone the repository manually.

---

## Prerequisites

- A local or remote machine running Linux (Debian/Ubuntu) or macOS.  
- **sudo** access on that machine (for package installation).  
- On the remote machine: SSH client installed and SSH access configured (e.g., `user@host`).  
- An active internet connection to download packages and the script.  
- If `gh` is missing, the script will install it automatically.

---

## Local Installation

1. **Clone this repository** (on the `api-key-github` branch):
   ```bash
   git clone git@github.com:charlesvdd/administrator-neomnia.git
   cd administrator-neomnia
   git checkout api-key-github
