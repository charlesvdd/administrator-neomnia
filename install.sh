#!/usr/bin/env bash
#===============================================================================
#
# install.sh — Installation Git & GitHub CLI avec prompts obligatoires
#
# Auteur   : Charles van den Driessche (version modifiée)
# Site Web : https://www.neomnia.net
# Licence  : GNU GPL v3
#
#===============================================================================

set -euo pipefail

#═══════════════════════════════════════════════════════════════════════════════
#   Fonctions utilitaires
#═══════════════════════════════════════════════════════════════════════════════

# Affiche une barre de titre décorative
print_header() {
    local title="$1"
    echo
    echo "───────────────────────────────────────────────────────────────────────────────"
    echo "   ${title}"
    echo "───────────────────────────────────────────────────────────────────────────────"
}

# Vérifie si la commande passée en argument existe
command_exists() {
    command -v "$1" &>/dev/null
}

#═══════════════════════════════════════════════════════════════════════════════
#   1) Demande des informations utilisateur (en boucle tant que vide)
#═══════════════════════════════════════════════════════════════════════════════

print_header "Configuration de GitHub"

# 1.1) Demander le nom d’utilisateur GitHub (obligatoire)
while true; do
    read -rp "➤ Entrez votre nom d’utilisateur GitHub (username) : " GITHUB_USER
    if [[ -n "$GITHUB_USER" ]]; then
        echo "→ Nom d’utilisateur GitHub défini : $GITHUB_USER"
        break
    else
        echo "⚠ Le nom d’utilisateur ne peut pas être vide. Veuillez réessayer."
    fi
done

# 1.2) (Optionnel) On attend la fin de l’installation de gh avant de demander le token
ASK_GITHUB_TOKEN_LATER=true

#═══════════════════════════════════════════════════════════════════════════════
#   2) Mise à jour du système
#═══════════════════════════════════════════════════════════════════════════════

print_header "Mise à jour du système"
echo "  - Mise à jour des listes de paquets (apt-get update)…"
sudo apt-get update -y
echo "  - Mise à niveau des paquets installés (apt-get upgrade)…"
sudo apt-get upgrade -y
echo "✔ Système Linux mis à jour."

#═══════════════════════════════════════════════════════════════════════════════
#   3) Installation de Git et GitHub CLI (gh)
#═══════════════════════════════════════════════════════════════════════════════

print_header "Installation de Git et GitHub CLI"

# 3.1) Installer Git si manquant
if ! command_exists git; then
    echo "  - Installation de Git…"
    sudo apt-get install -y git
else
    echo "  - Git est déjà installé (version : $(git --version))."
fi

# 3.2) Installer GitHub CLI (gh) si manquant
if ! command_exists gh; then
    echo "  - Détection Ubuntu/Debian (apt-get)."
    # Installer curl si nécessaire
    if ! command_exists curl; then
        sudo apt-get install -y curl
    fi
    echo "  - Import de la clé GPG officielle de GitHub CLI…"
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
         | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg

    echo "  - Ajout du dépôt GitHub CLI à /etc/apt/sources.list.d/gh-cli.list…"
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
https://cli.github.com/packages stable main" \
         | sudo tee /etc/apt/sources.list.d/gh-cli.list >/dev/null

    echo "  - Mise à jour apt…"
    sudo apt-get update -y
    echo "  - Installation de GitHub CLI (gh)…"
    sudo apt-get install -y gh
    echo "✔ GitHub CLI (gh) installé."
else
    echo "  - GitHub CLI (gh) est déjà installé (version : $(gh --version | head -n1))."
fi

#═══════════════════════════════════════════════════════════════════════════════
#   4) (Optionnel) Authentification GitHub CLI avec token (en boucle)
#═══════════════════════════════════════════════════════════════════════════════

if [[ "$ASK_GITHUB_TOKEN_LATER" == true ]]; then
    print_header "Authentification GitHub CLI (gh)"
    echo "Maintenant que 'gh' est installé, vous pouvez vous authentifier en utilisant un token GitHub."
    echo "  → Pour créer un token, allez sur : https://github.com/settings/tokens"
    echo "     * Sélectionnez au moins le scope 'repo' (ou autres selon vos besoins)."
    echo

    # 4.1) Boucle tant que TOKEN vide
    while true; do
        read -rp "➤ Entrez votre token GitHub (il restera en mémoire le temps de l'exécution) : " GITHUB_TOKEN
        if [[ -n "$GITHUB_TOKEN" ]]; then
            echo "$GITHUB_TOKEN" | gh auth login --with-token
            echo "✔ Authentification GitHub CLI réussie."
            break
        else
            echo "⚠ Le token ne peut pas être vide. Veuillez coller le token généré sur GitHub."
        fi
    done
fi

#═══════════════════════════════════════════════════════════════════════════════
#   5) Configuration Git locale + Génération SSH (le cas échéant)
#═══════════════════════════════════════════════════════════════════════════════

print_header "Configuration Git locale"

# 5.1) Configurer le nom et l’email Git globalement (si non configuré)
CURRENT_NAME="$(git config --global user.name || echo "")"
CURRENT_EMAIL="$(git config --global user.email || echo "")"
if [[ -z "$CURRENT_NAME" ]]; then
    read -rp "➤ Entrez votre nom complet pour Git (par ex. “John Doe”) : " GIT_FULLNAME
    git config --global user.name "$GIT_FULLNAME"
    echo "→ Git user.name configuré à '$GIT_FULLNAME'."
else
    echo "→ Git user.name existant : $CURRENT_NAME"
fi

if [[ -z "$CURRENT_EMAIL" ]]; then
    read -rp "➤ Entrez votre email pour Git (par ex. “email@exemple.com”) : " GIT_EMAIL
    git config --global user.email "$GIT_EMAIL"
    echo "→ Git user.email configuré à '$GIT_EMAIL'."
else
    echo "→ Git user.email existant : $CURRENT_EMAIL"
fi

# 5.2) Générer une paire de clés SSH si aucune n'existe
if [[ ! -f "$HOME/.ssh/id_rsa.pub" ]]; then
    echo "  - Aucune clé SSH détectée. Génération d’une paire de clés SSH…"
    read -rp "   Entrez votre email pour la clé SSH (laissez vide pour utiliser l’email Git configuré) : " SSH_EMAIL
    if [[ -z "$SSH_EMAIL" ]]; then
        SSH_EMAIL="$GIT_EMAIL"
    fi
    ssh-keygen -t rsa -b 4096 -C "$SSH_EMAIL" -f "$HOME/.ssh/id_rsa" -N ""
    echo "✔ Paire de clés SSH générée."
else
    echo "  - Clé SSH existante détectée : ~/.ssh/id_rsa.pub"
fi

echo
echo "→ Clé publique SSH (~/.ssh/id_rsa.pub) :"
echo "---------------------------------------------------------"
cat "$HOME/.ssh/id_rsa.pub"
echo "---------------------------------------------------------"
echo "Copiez cette clé publique et ajoutez-la à vos clés SSH GitHub :"
echo "  1) Allez sur : https://github.com/settings/keys"  
echo "  2) Cliquez sur « New SSH key » puis collez la clé."
echo

#═══════════════════════════════════════════════════════════════════════════════
#   6) Vérification finale et message de fin
#═══════════════════════════════════════════════════════════════════════════════

print_header "Vérification finale"

echo "  - Utilisateur GitHub configuré : $GITHUB_USER"
if command_exists gh; then
    echo "  - Statut de l’authentification 'gh' : $(gh auth status 2>&1 | head -n1)"
fi
echo
echo "✔ Installation terminée. Vous pouvez maintenant :"
echo "   • Cloner un dépôt avec SSH : git clone git@github.com:${GITHUB_USER}/NOM_DU_REPO.git"
echo "   • Utiliser 'gh' pour gérer vos repos : gh repo list $GITHUB_USER"
echo
echo "Merci d’avoir utilisé ce script ! — Charles van den Driessche"
