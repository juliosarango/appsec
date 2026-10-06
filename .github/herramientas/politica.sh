#!/usr/bin/env bash
# Cuenta hallazgos por severidad a partir del reporte de cada herramienta.
#   politica.sh resumen     <herramienta> <reporte>  -> tabla Markdown
#   politica.sh bloqueantes <herramienta> <reporte>  -> número de hallazgos que rompen el build
# Lo usan el workflow y demo/demo.sh, así la política es la misma en CI y en local.
set -euo pipefail
modo=$1 herramienta=$2 reporte=$3

case $herramienta in
  gitleaks)
    # Cualquier secreto bloquea.
    n=$(jq '[.runs[].results[]] | length' "$reporte")
    titulo="Gitleaks"; cols="Secretos"; vals="$n"; bloq=$n ;;
  kics)
    c() { jq ".severity_counters.$1 // 0" "$reporte"; }
    titulo="KICS"; cols="Crítica | Alta | Media | Baja | Info"
    vals="$(c CRITICAL) | $(c HIGH) | $(c MEDIUM) | $(c LOW) | $(c INFO)"
    bloq=$(( $(c CRITICAL) + $(c HIGH) )) ;;
  osv)
    # max_severity es el CVSS más alto del grupo de advisories; vacío = sin puntuación.
    q='[.results[]?.packages[]?.groups[]? | (.max_severity // "")]'
    c() { jq "$q | map(select(. != \"\") | tonumber | select($1)) | length" "$reporte"; }
    crit=$(c '. >= 9'); alta=$(c '. >= 7 and . < 9'); media=$(c '. >= 4 and . < 7'); baja=$(c '. < 4')
    sin=$(jq "$q | map(select(. == \"\")) | length" "$reporte")
    titulo="OSV-Scanner"; cols="Crítica | Alta | Media | Baja | Sin CVSS"
    vals="$crit | $alta | $media | $baja | $sin"; bloq=$(( crit + alta )) ;;
  semgrep)
    # Semgrep CE usa ERROR/WARNING/INFO; ERROR equivale a severidad alta.
    c() { jq "[.results[] | select(.extra.severity == \"$1\")] | length" "$reporte"; }
    titulo="Semgrep"; cols="Alta (ERROR) | Media (WARNING) | Baja (INFO)"
    vals="$(c ERROR) | $(c WARNING) | $(c INFO)"; bloq=$(c ERROR) ;;
  zap)
    # Baseline es pasivo: reporta, nunca bloquea.
    c() { jq "[.site[].alerts[] | select(.riskcode == \"$1\")] | length" "$reporte"; }
    titulo="ZAP baseline (no bloquea)"; cols="Alta | Media | Baja | Info"
    vals="$(c 3) | $(c 2) | $(c 1) | $(c 0)"; bloq=0 ;;
  *) echo "herramienta desconocida: $herramienta" >&2; exit 2 ;;
esac

if [ "$modo" = bloqueantes ]; then
  echo "$bloq"
else
  sep=$(echo "$cols" | sed 's/[^|]*/---/g')
  printf '### %s\n\n| %s |\n|%s|\n| %s |\n\n' "$titulo" "$cols" "$sep" "$vals"
fi
