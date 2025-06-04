#!/usr/bin/env bash
#
# raw-install.sh
#
# This script defines a `raw` function that downloads (via curl)
# any `.sh` file from your repository’s main branch on GitHub and executes it directly.
#
# Usage:
#   1. Save this file as raw-install.sh
#   2. Make it executable: chmod +x raw-install.sh
#   3. Run it like this: sudo ./raw-install.sh install.sh
#
# Examples:
#   sudo ./raw-install.sh install.sh
#   sudo ./raw-install.sh path/to/another-script.sh
#

set -euo pipefail

# Base URL for raw file content on the GitHub repository
BASE_URL="https://raw.githubusercontent.com/charlesvdd/administrator-neomnia/main"

# Function raw: fetches a .sh script via curl and runs it in-memory with Bash
raw() {
    local remote_path="$1"
    if [[ -z "$remote_path" ]]; then
        echo "Usage: raw <path/to/script.sh>"
        return 1
    fi
    echo "→ Downloading and running '$remote_path' from GitHub…"
    bash <(curl -fsSL "${BASE_URL}/${remote_path}")
}

# If this file is invoked directly with arguments, pass them to raw()
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -lt 1 ]]; then
        echo "Error: Please specify the path to the script to run (e.g., install.sh)."
        exit 1
    fi
    raw "$1"
fi
