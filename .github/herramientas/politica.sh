#!/usr/bin/env bash
# Cuenta hallazgos por severidad a partir del reporte de cada herramienta.
#   politica.sh resumen     <herramienta> <reporte>  -> tabla Markdown con conteos y detalle plegable
#   politica.sh bloqueantes <herramienta> <reporte>  -> número de hallazgos que rompen el build
# Lo usan el workflow y demo/demo.sh, así la política es la misma en CI y en local.
set -euo pipefail
modo=$1 herramienta=$2 reporte=$3

case $herramienta in
  gitleaks)
    # Cualquier secreto bloquea.
    n=$(jq '[.runs[].results[]] | length' "$reporte")
    titulo="Gitleaks"; cols="Secretos"; vals="$n"; bloq=$n
    det='[.runs[].results[] | .locations[0].physicalLocation as $l
      | ["Secreto", .ruleId, "\($l.artifactLocation.uri):\($l.region.startLine) (commit \(.partialFingerprints.commitSha[0:7]))"]]' ;;
  kics)
    c() { jq ".severity_counters.$1 // 0" "$reporte"; }
    titulo="KICS"; cols="Crítica | Alta | Media | Baja | Info"
    vals="$(c CRITICAL) | $(c HIGH) | $(c MEDIUM) | $(c LOW) | $(c INFO)"
    bloq=$(( $(c CRITICAL) + $(c HIGH) ))
    det='{"CRITICAL":0,"HIGH":1,"MEDIUM":2,"LOW":3,"INFO":4} as $r | [.queries[] as $q | $q.files[]
      | {r: $r[$q.severity], f: [$q.severity, $q.query_name, "\(.file_name | sub("^(\\.\\./)*repo/"; "")):\(.line)"]}]
      | sort_by(.r) | map(.f)' ;;
  osv)
    # max_severity es el CVSS más alto del grupo de advisories; vacío = sin puntuación.
    q='[.results[]?.packages[]?.groups[]? | (.max_severity // "")]'
    c() { jq "$q | map(select(. != \"\") | tonumber | select($1)) | length" "$reporte"; }
    crit=$(c '. >= 9'); alta=$(c '. >= 7 and . < 9'); media=$(c '. >= 4 and . < 7'); baja=$(c '. < 4')
    sin=$(jq "$q | map(select(. == \"\")) | length" "$reporte")
    titulo="OSV-Scanner"; cols="Crítica | Alta | Media | Baja | Sin CVSS"
    vals="$crit | $alta | $media | $baja | $sin"; bloq=$(( crit + alta ))
    # Se muestra el CVE si existe; si no, el id del advisory.
    det='[.results[]? as $s | $s.packages[]? as $p | $p.groups[]? as $g
      | ([$g.aliases[]? | select(startswith("CVE-"))] | if length > 0 then . else $g.ids end) as $ids
      | {r: -(($g.max_severity // "0") | tonumber), f: ["CVSS \($g.max_severity // "?")",
         "\($p.package.name)@\($p.package.version): \($ids | join(", "))",
         ($s.source.path | sub("^(/repo/|/github/workspace/|\\./)"; ""))]}]
      | sort_by(.r) | map(.f)' ;;
  semgrep)
    # Semgrep CE usa ERROR/WARNING/INFO; ERROR equivale a severidad alta.
    c() { jq "[.results[] | select(.extra.severity == \"$1\")] | length" "$reporte"; }
    titulo="Semgrep"; cols="Alta (ERROR) | Media (WARNING) | Baja (INFO)"
    vals="$(c ERROR) | $(c WARNING) | $(c INFO)"; bloq=$(c ERROR)
    det='{"ERROR":0,"WARNING":1,"INFO":2} as $r | [.results[]
      | {r: $r[.extra.severity], f: [.extra.severity, (.check_id | split(".") | last), "\(.path):\(.start.line)"]}]
      | sort_by(.r) | map(.f)' ;;
  zap)
    # Baseline es pasivo: reporta, nunca bloquea. El JSON incluye las alertas que
    # rules.tsv marca como IGNORE, así que se descuentan y se muestran aparte.
    reglas="$(dirname "$reporte")/rules.tsv"
    ign=$( if [ -f "$reglas" ]; then awk -F'\t' '$2 == "IGNORE" { print $1 }' "$reglas"; fi | jq -R . | jq -sc .)
    c() { jq --argjson ign "$ign" "[.site[].alerts[] | select(.riskcode == \"$1\") | select(.pluginid as \$p | \$ign | index(\$p) | not)] | length" "$reporte"; }
    ni=$(jq --argjson ign "$ign" '[.site[].alerts[] | select(.pluginid as $p | $ign | index($p))] | length' "$reporte")
    titulo="ZAP baseline (no bloquea)"; cols="Alta | Media | Baja | Info | Ignoradas (rules.tsv)"
    vals="$(c 3) | $(c 2) | $(c 1) | $(c 0) | $ni"; bloq=0
    det='[.site[].alerts[] | (.pluginid as $p | $ign | index($p)) as $i
      | {r: -(.riskcode | tonumber), f: [(.riskdesc | split(" ")[0]),
         "\(.name) [\(.pluginid)]\(if $i then " (ignorada)" else "" end)",
         "ej.: \(.instances[0].uri)"]}]
      | sort_by(.r) | map(.f)' ;;
  *) echo "herramienta desconocida: $herramienta" >&2; exit 2 ;;
esac

if [ "$modo" = bloqueantes ]; then
  echo "$bloq"
else
  sep=$(echo "$cols" | sed 's/[^|]*/---/g')
  printf '### %s\n\n| %s |\n|%s|\n| %s |\n\n' "$titulo" "$cols" "$sep" "$vals"
  # Detalle plegable: el resumen sigue siendo corto, pero cada hallazgo tiene su archivo y línea.
  filas=$(jq -r --argjson ign "${ign:-[]}" "$det"' | .[]
    | map(tostring | gsub("\\|"; "\\|")) | "| \(.[0]) | \(.[1]) | `\(.[2])` |"' "$reporte")
  if [ -n "$filas" ]; then
    printf '<details><summary>Ver %s hallazgo(s)</summary>\n\n| Severidad | Hallazgo | Ubicación |\n|---|---|---|\n%s\n\n</details>\n\n' \
      "$(echo "$filas" | wc -l)" "$filas"
  fi
fi
