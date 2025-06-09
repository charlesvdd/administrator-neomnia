# Kickstart Semantic Versioning

A simple, interactive Bash script to set up **Semantic Versioning** in your Git repository. It handles initialization, creates a configuration file, sets up an initial version, and provides a `bump_version.sh` helper to increment MAJOR, MINOR, or PATCH versions, commit changes, and push tags.

---

## 📋 Features

* **Interactive setup**: configure version file, tag prefix, initial version, and commit message template.
* **Semantic Versioning**: follows MAJOR.MINOR.PATCH rules.
* **Author**: Charles VDD
* **Automatic Git tags**: creates annotated tags and commits.
* **Polished logs**: clear, colored messages with emojis for a friendly install experience.

---

## 🚀 Installation & Usage

1. **Download the script**

   ```bash
   wget -qO kickstart-versioning.sh \
     https://raw.githubusercontent.com/charlesvdd/administrator-neomnia/versioning/kickstart-versioning.sh
   chmod +x kickstart-versioning.sh
   ```

2. **Run the installer**

   ```bash
   ./kickstart-versioning.sh
   ```

   Follow the on-screen prompts. You will configure:

   * Version file name (default: `VERSION`)
   * Tag prefix (default: `v`)
   * Initial version (default: `0.1.0`)
   * Commit message template (use `%s` for the new version)

3. **Bump versions**

   ```bash
   ./bump_version.sh {patch|minor|major}
   ```

   Where:

   * `patch` → 0.1.0 → 0.1.1
   * `minor` → 0.1.0 → 0.2.0
   * `major` → 0.1.0 → 1.0.0

---

## 📄 bump\_version.sh

```bash
#!/usr/bin/env bash
# bump_version.sh — Increment semantic version, commit & push tags
set -e

# Load configuration
source .versionrc

log() {
  echo -e "\n🔧 [BUMP] $1"
}

# Ensure argument is valid
if [[ ! $1 =~ ^(major|minor|patch)$ ]]; then
  echo "Usage: $0 {major|minor|patch}"
  exit 1
fi

# Read old version
old_version=$(<"$VERSION_FILE")
IFS='.' read -r major minor patch <<< "$old_version"

case $1 in
  major) major=$((major+1)); minor=0; patch=0 ;;  
  minor) minor=$((minor+1)); patch=0 ;;  
  patch) patch=$((patch+1)) ;;  
esac

new_version="$major.$minor.$patch"

echo "$new_version" > "$VERSION_FILE"

git add "$VERSION_FILE"
# Format commit message
commit_message=$(printf "$COMMIT_MSG" "$new_version")
git commit -m "$commit_message"

tag_name="$TAG_PREFIX$new_version"
git tag -a "$tag_name" -m "Release $new_version"

git push origin --follow-tags

log "Version bumped: $old_version → $new_version"
```

---

## 🛠️ Installer Script (kickstart-versioning.sh)

```bash
#!/usr/bin/env bash
# kickstart-versioning.sh — Setup Semantic Versioning
# Author: Charles VDD
# License: MIT

set -e

# --- Color & Emoji Logging ---
info() { echo -e "\e[34mℹ️  $1\e[0m"; }
success() { echo -e "\e[32m✅ $1\e[0m"; }
error() { echo -e "\e[31m❌ $1\e[0m"; exit 1; }

# --- Prerequisites ---
info "Checking Git CLI..."
command -v git >/dev/null 2>&1 || error "Git not found. Please install Git and retry."
success "Git is installed: $(git --version)"

# Check or set up remote origin
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  info "Detected Git repository."
  if git remote get-url origin >/dev/null 2>&1; then
    origin_url=$(git remote get-url origin)
    info "Remote 'origin' → $origin_url"
    git ls-remote origin >/dev/null 2>&1 || error "Cannot reach origin. Check SSH/HTTPS setup."
    success "Origin reachable."
  else
    read -p "Enter GitHub remote URL for 'origin': " origin_url
    git remote add origin "$origin_url"
    success "Added remote origin: $origin_url"
  fi
else
  info "No Git repo found. Will initialize one later."
fi

# --- Interactive Configuration ---
info "Setting up Semantic Versioning configuration..."
read -p "Version file name (default VERSION): " VERSION_FILE
VERSION_FILE=${VERSION_FILE:-VERSION}
read -p "Tag prefix (default v): " TAG_PREFIX
TAG_PREFIX=${TAG_PREFIX:-v}
read -p "Initial version (default 0.1.0): " INITIAL_VERSION
INITIAL_VERSION=${INITIAL_VERSION:-0.1.0}
read -p "Commit message template (use %s for new version, default 'chore: bump to %s'): " COMMIT_MSG
COMMIT_MSG=${COMMIT_MSG:-"chore: bump to %s"}

# Confirm and write config
cat > .versionrc <<EOF
VERSION_FILE="$VERSION_FILE"
TAG_PREFIX="$TAG_PREFIX"
COMMIT_MSG="$COMMIT_MSG"
EOF
success "Configuration saved to .versionrc"

# --- Initialize Git Repo & Version ---
if [[ ! -d .git ]]; then
  git init
  success "Initialized new Git repository."
fi

if [[ ! -f $VERSION_FILE ]]; then
  echo "$INITIAL_VERSION" > "$VERSION_FILE"
  git add "$VERSION_FILE" .versionrc
  git commit -m "chore: initial version $INITIAL_VERSION"
  git tag -a "${TAG_PREFIX}${INITIAL_VERSION}" -m "Release $INITIAL_VERSION"
  success "Created $VERSION_FILE (version $INITIAL_VERSION) and tagged ${TAG_PREFIX}${INITIAL_VERSION}."
else
  info "$VERSION_FILE already exists, skipping creation."
fi

# --- Generate bump_version.sh ---
cat > bump_version.sh <<'EOS'
$(sed -n '1,200p' kickstart-versioning.sh | sed '1,40d')
EOS
chmod +x bump_version.sh
git add bump_version.sh
git commit -m "chore: add bump_version.sh"
success "Generated bump_version.sh and committed to repo."

success "🎉 Semantic Versioning setup complete! Use './bump_version.sh {patch|minor|major}' to bump versions."
```
