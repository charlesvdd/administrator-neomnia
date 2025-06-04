# Administrator Neomnia – Git & GitHub CLI Installation Script

**Author:** Charles van den Driessche  
**Website:** [www.neomnia.net](https://www.neomnia.net)  
**License:** GNU GPL v3.0  

---

## One-Line Install & Launch (Directly from GitHub)

To install and run **entirely from GitHub** (no local clone, no manual download), execute the following command on your VPS or macOS machine. It will:

1. Download `install.sh` from the `api-key-github` branch.  
2. Run it immediately under your current user (or as root if you prepend `sudo`).  

```bash
sudo curl -fsSL https://raw.githubusercontent.com/charlesvdd/administrator-neomnia/api-key-github/install.sh | bash
