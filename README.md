#!/bin/bash

##
## Fonction RAW pour afficher le README.md depuis GitHub
##
## Usage :
##   raw_readme <utilisateur> <répo> [<branche>]
##
## Exemples :
##   raw_readme charlesvdd administrator-neomnia            # branche par défaut : main
##   raw_readme charlesvdd administrator-neomnia init       # récupère la branche init
##

function raw_readme() {
  local user="$1"
  local repo="$2"
  local branch="${3:-main}"   # si pas de 3ᵉ argument, on prend « main »
  local raw_url="https://raw.githubusercontent.com/${user}/${repo}/${branch}/README.md"

  if [[ -z "$user" || -z "$repo" ]]; then
    echo "Usage : raw_readme <utilisateur> <répo> [<branche>]"
    return 1
  fi

  echo -e "\n📥 Fetching RAW README from:"
  echo "         $raw_url"
  echo

  # On utilise curl pour récupérer le contenu brut
  curl -fsSL "$raw_url" || {
    echo -e "\n⚠️ Cannot fetch README.md (Vérifiez le nom d’utilisateur, le répo ou la branche)."
    return 2
  }

  echo
}
