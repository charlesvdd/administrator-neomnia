# Administrator Neomnia – Git & GitHub CLI Installation Script

**Author:** Charles van den Driessche
**Website:** [www.neomnia.net](http://www.neomnia.net)
**License:** GNU GPL v3.0

## Description

This script automates the process of setting up a GitHub repository on your VPS or local machine. It prompts for your GitHub username and API key, validates them, and stores them in an encoded format for security.

## Prerequisites

- Ensure you have `curl`, `git`, and `base64` installed on your system.
- A GitHub API key with appropriate permissions.

## Installation

### One-Line Install & Launch (Directly from GitHub)

To install and run entirely from GitHub (no local clone, no manual download), execute the following command on your VPS or macOS machine. It will:

1. Download `install.sh` from the `api-key-github` branch.
2. Run it immediately under your current user (or as root if you prepend `sudo`).

```bash
sudo curl -fsSL https://raw.githubusercontent.com/charlesvdd/administrator-neomnia/api-key-github/install.sh | bash
