# administrator-neomnia

A collection of Bash installation scripts to prepare and configure a VPS environment.  
Each branch contains one or more executable `.sh` scripts meant to be run directly with Bash.

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Repository Structure](#repository-structure)
3. [Getting Started](#getting-started)
4. [Usage](#usage)
5. [Contributing](#contributing)
6. [License](#license)

---

## Project Overview

This repository — **administrator-neomnia** — provides a set of Bash scripts designed to automate the installation and setup of various components on a fresh VPS. Each branch typically holds a specific purpose or stack (e.g., LAMP setup, Docker, monitoring tools), and each `.sh` file is written so that it can be executed directly with Bash.

Rather than manually copy-pasting commands, you can simply run the relevant script(s) to provision your server.

---

## Repository Structure

- **Branches**  
  Each branch represents a different set of installation scripts or configuration tasks. For example:
  - `master` or `main`: Core utilities and common prerequisites.
  - Other branches: Specific stacks (e.g., `lamp-setup`, `docker-install`, `nginx-php`).

- **Scripts**  
  In each branch, you will find one or more `.sh` files, each annotated with comments explaining its purpose and usage. They may be named things like `install.sh`, `setup-docker.sh`, `nginx-php.sh`, etc.

---

## Getting Started

1. **Clone the repository**  
   ```bash
   git clone https://github.com/charlesvdd/administrator-neomnia.git
   cd administrator-neomnia
