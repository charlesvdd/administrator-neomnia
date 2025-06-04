# Execute Installation Script via “RAW” from GitHub

This README explains how to fetch and run the installation script directly from GitHub using a simple “raw” function in Bash. No additional dependencies are required beyond `bash` and `curl`.

---

## Function: `raw_readme`

Add the following function to your local shell (e.g., in `~/.bashrc`, `~/.bash_profile`, or in a small helper file like `utils.sh`):

```bash
#!/bin/bash

##
## Function: raw_readme
##
## Fetches and displays the raw contents of README.md (or any file) from GitHub.
##
## Usage:
##   raw_readme <github_user> <repo_name> [<branch>] [<path_to_file>]
##
## Examples:
##   raw_readme charlesvdd administrator-neomnia                # Defaults to branch “main” and file README.md
##   raw_readme charlesvdd administrator-neomnia init           # README.md on branch “init”
##   raw_readme charlesvdd administrator-neomnia init scripts/install.sh  # Any file on the “init” branch
##

function raw_readme() {
  local user="$1"
  local repo="$2"
  local branch="${3:-main}"      # Default branch = “main” if not specified
  local file_path="${4:-README.md}"  # Default file = “README.md” if not specified
  local raw_url="https://raw.githubusercontent.com/${user}/${repo}/${branch}/${file_path}"

  if [[ -z "$user" || -z "$repo" ]]; then
    echo "Usage: raw_readme <github_user> <repo_name> [<branch>] [<path_to_file>]"
    return 1
  fi

  echo -e "\n📥 Fetching raw file from:"
  echo "         $raw_url"
  echo

  # Use curl to retrieve and display the file’s raw content
  curl -fsSL "$raw_url" || {
    echo -e "\n⚠️  Cannot fetch file (check user, repo, branch, or path)."
    return 2
  }

  echo
}
