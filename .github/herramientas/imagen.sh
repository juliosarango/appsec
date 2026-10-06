#!/usr/bin/env bash
# Uso: imagen.sh <nombre>  ->  imprime la referencia fijada (tag@digest) de esa herramienta.
set -euo pipefail
awk -v n="$1" '$1 == "FROM" && $3 == "AS" && $4 == n { print $2; found=1 } END { exit !found }' \
  "$(dirname "$0")/Dockerfile"
