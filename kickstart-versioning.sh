#!/usr/bin/env bash
# kickstart-versioning.sh (root-aware)
set -e

# 0) auto-élévation
if [[ "$(id -u)" -ne 0 ]]; then
  SUDO="sudo"
else
  SUDO=""
fi

# 1) Vérification de la CLI Git
if ! command -v git >/dev/null; then
  echo "❌ Git n'est pas installé."
  exit 1
fi
echo "✅ Git CLI détectée : $(git --version)"

# 2) Vérif/ajout du remote origin + test connexion
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if git remote get-url origin >/dev/null 2>&1; then
    REMOTE_URL=$(git remote get-url origin)
    echo "ℹ️ Remote 'origin' détecté → $REMOTE_URL"
  else
    read -p "URL du remote origin : " REMOTE_URL
    git remote add origin "$REMOTE_URL"
    echo "Remote 'origin' ajouté → $REMOTE_URL"
  fi
  echo "Test de connexion à origin…"
  git ls-remote origin >/dev/null
  echo "✅ Connexion réussie."
else
  echo "⚠️ Pas dans un dépôt Git — repos initialisé plus bas."
fi

# 3) Config interactif (VERSION_FILE, TAG_PREFIX, INITIAL_VERSION, COMMIT_MSG)
# … (inchangé)

# 4) Init dépôt + création VERSION + tag initial
# … (inchangé)

# 5) Génération de bump_version.sh
# … (inchangé)

echo "🎉 Prêt ! Lancez ./bump_version.sh {patch|minor|major}"
