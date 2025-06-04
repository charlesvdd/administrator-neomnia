# Administrator Neomnia – Automatic Remote Setup

This repository provides a Bash script (`install.sh`) to prepare a Next.js/React project environment on a fresh Debian/Ubuntu machine. All steps are designed to be executed remotely—there is no need to clone the repository locally beforehand.

---

## Table of Contents

1. [Overview](#overview)  
2. [Prerequisites](#prerequisites)  
3. [Remote Installation via `raw`](#remote-installation-via-raw)  
4. [What the Script Does](#what-the-script-does)  
5. [Usage After Installation](#usage-after-installation)  
6. [Contributing](#contributing)  
7. [License](#license)  

---

## Overview

Instead of cloning this repository to your server first, you can use a single command to fetch and run the installer script directly from GitHub. This “remote execution only” approach ensures you never need to maintain a local copy.

---

## Prerequisites

- A fresh Debian/Ubuntu machine (root or sudo access is required).  
- Internet connection on the target machine.  

---

## Remote Installation via `raw`

1. SSH into your target machine as root (or a user with sudo privileges).  
2. Define the following Bash function in your shell session:
   ```bash
   curl -sSL https://raw.githubusercontent.com/charlesvdd/administrator-neomnia/next-project/install.sh | bash my-nextjs-app
