#!/usr/bin/env bash
# kickstart-versioning.sh
# -----------------------------------------
# Script d’installation d’un modèle de versionning sémantique.
# Usage : bash kickstart-versioning.sh

set -e

### 1) Vérification de la CLI Git ###
if ! command -v git >/dev/null; then
  echo "❌ Git n'est pas installé sur ce système."
  exit 1
fi
echo "✅ Git CLI détectée : $(git --version)"

### 2) Vérification du remote GitHub ###
# Si on est déjà dans un dépôt, on teste le remote origin
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if git remote get-url origin >/dev/null 2>&1; then
    REMOTE_URL=$(git remote get-url origin)
    echo "ℹ️ Remote 'origin' détecté → $REMOTE_URL"
    echo "Test de connexion à GitHub (ls-remote)…"
    if git ls-remote origin >/dev/null 2>&1; then
      echo "✅ Connexion à 'origin' réussie."
    else
      echo "⚠️ Échec de la connexion à 'origin'. Vérifiez vos clés SSH ou votre HTTPS."
      exit 1
    fi
  else
    echo "⚠️ Pas de remote 'origin' configuré."
    read -p "Entrez l'URL GitHub du remote origin (ex. git@github.com:User/Repo.git) : " REMOTE_URL
    git remote add origin "$REMOTE_URL"
    echo "Remote 'origin' ajouté → $REMOTE_URL"
    echo "Test de connexion…"
    if git ls-remote origin >/dev/null 2>&1; then
      echo "✅ Connexion à 'origin' réussie."
    else
      echo "❌ Échec de la connexion à 'origin'. Abandon."
      exit 1
    fi
  fi
else
  echo "⚠️ Vous n'êtes pas dans un dépôt Git. Le dépôt sera initialisé plus tard."
fi

### 3) Collecte des paramètres de configuration ###
echo
echo "=== Configuration du versionning sémantique ==="
read -p "Fichier de version (par défaut VERSION) : " VERSION_FILE
VERSION_FILE=${VERSION_FILE:-VERSION}

read -p "Préfixe de tag (par défaut v) : " TAG_PREFIX
TAG_PREFIX=${TAG_PREFIX:-v}

read -p "Version initiale (par défaut 0.1.0) : " INITIAL_VERSION
INITIAL_VERSION=${INITIAL_VERSION:-0.1.0}

read -p "Message de commit pour bump (avec %s pour la nouvelle version, ex. \"chore: bump to %s\") : " COMMIT_MSG
COMMIT_MSG=${COMMIT_MSG:-"chore: bump to %s"}

echo
echo "Les paramètres suivants seront enregistrés :"
echo "  • VERSION_FILE = $VERSION_FILE"
echo "  • TAG_PREFIX   = $TAG_PREFIX"
echo "  • INITIAL_VER  = $INITIAL_VERSION"
echo "  • COMMIT_MSG   = $COMMIT_MSG"
echo
read -p "OK pour créer le fichier de config .versionrc ? [O/n] " ans
ans=${ans:-O}
if [[ ! $ans =~ ^[Oo] ]]; then
  echo "Annulation. Vous pouvez relancer le script ou créer manuellement .versionrc."
  exit 1
fi

cat > .versionrc <<EOF
# Configuration sémantique
VERSION_FILE="$VERSION_FILE"
TAG_PREFIX="$TAG_PREFIX"
COMMIT_MSG="$COMMIT_MSG"
EOF

### 4) Initialisation du dépôt Git et création de VERSION ###
if [[ ! -d .git ]]; then
  git init
  echo "✅ Dépôt Git initialisé."
fi

if [[ ! -f $VERSION_FILE ]]; then
  echo "$INITIAL_VERSION" > "$VERSION_FILE"
  git add "$VERSION_FILE" .versionrc
  git commit -m "chore: initial version $INITIAL_VERSION"
  git tag -a "${TAG_PREFIX}${INITIAL_VERSION}" -m "Release ${INITIAL_VERSION}"
  echo "✅ Fichier $VERSION_FILE créé avec version $INITIAL_VERSION et tag ${TAG_PREFIX}${INITIAL_VERSION}."
else
  echo "ℹ️ Le fichier $VERSION_FILE existe déjà, je le laisse intact."
fi

### 5) Génération du script bump_version.sh ###
cat > bump_version.sh <<'EOS'
#!/usr/bin/env bash
# bump_version.sh — incrémente MAJOR/MINOR/PATCH et pousse tag+commit
set -e
source .versionrc

if [[ ! $1 =~ ^(major|minor|patch)$ ]]; then
  echo "Usage: $0 {major|minor|patch}"
  exit 1
fi

old=$(<"$VERSION_FILE")
IFS='.' read -r M m p <<< "$old"

case $1 in
  major) M=$((M+1)); m=0; p=0 ;;
  minor) m=$((m+1)); p=0 ;;
  patch) p=$((p+1)) ;;
esac

new="$M.$m.$p"
echo "$new" > "$VERSION_FILE"
git add "$VERSION_FILE"
msg=$(printf "$COMMIT_MSG" "$new")
git commit -m "$msg"
git tag -a "${TAG_PREFIX}${new}" -m "Release $new"
git push origin --follow-tags
echo "✅ Version $old → $new, tag ${TAG_PREFIX}${new} poussé."
EOS

chmod +x bump_version.sh
git add bump_version.sh
git commit -m "chore: add bump_version.sh"
echo "✅ Script bump_version.sh ajouté et commité."

echo
echo "🎉 Versionning sémantique prêt !"
echo "Pour bump la version :"
echo "  ./bump_version.sh {patch|minor|major}"
echo
echo "Si vous souhaitez modifier les règles, éditez .versionrc."
