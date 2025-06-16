# GitHub CLI & Git Installer Wrapper

This repository provides a convenient wrapper script (`git-wrapper.sh`) to automatically install Git and the GitHub CLI (`gh`), then prompt for your GitHub Personal Access Token (PAT) to authenticate `gh`. The wrapper detects missing dependencies, elevates privileges only when necessary, and ensures a streamlined setup on a fresh VPS or server.

## Features

- **Automatic detection and installation** of Git (via `apt-get` or `yum`).
- **Automatic detection and installation** of GitHub CLI (`gh`) from the official GitHub repository.
- **Interactive** or **non-interactive** PAT handling:
  - If `GITHUB_TOKEN` is set in your environment, the script skips the `read` prompt.
  - Otherwise, the script prompts you (in a TTY) to enter your PAT securely.
- **Base64 encoding** of the PAT and storage in `~/.github_token` with `chmod 600` permissions.
- **Authentication** of `gh` under your non-root user, followed by `gh config set user`.
- Elevation to **root only when installing** packages, then reverting to your original user for everything else.

## Usage

### One-Line Command

Run the following command in a single line. This will:

1. Download `git-wrapper.sh` to the current directory.
2. Make it executable (`chmod +x`).
3. Execute the script (`./git-wrapper.sh`).

```bash
sudo bash -c "curl -sL https://raw.githubusercontent.com/charlesvdd/administrator-neomnia/api-key-github/git-wrapper.sh -o git-wrapper.sh && chmod +x git-wrapper.sh && ./git-wrapper.sh"
