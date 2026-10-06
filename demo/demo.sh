#!/usr/bin/env bash
# Ejecuta en local las mismas etapas del pipeline, con las mismas imágenes y la misma política.
#
#   demo/demo.sh preparar            descarga las imágenes antes de la charla (ZAP pesa ~2.4 GB)
#   demo/demo.sh                     corre todas las etapas, con pausa entre cada una
#   demo/demo.sh semgrep zap         corre solo esas etapas
#   PAUSA=0 demo/demo.sh             sin pausas (para regenerar los reportes de respaldo)
#
# Los reportes quedan en reportes/<rama>/ y un resumen en reportes/<rama>/resumen.md.
set -uo pipefail

cd "$(dirname "$0")/.." || exit 1
H=.github/herramientas
img() { "$H/imagen.sh" "$1"; }
# Con tu uid, para que los reportes no queden con dueño root.
YO=(--user "$(id -u):$(id -g)" -e HOME=/tmp)

rama=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo local)
OUT=${OUT:-reportes/$rama}
PAUSA=${PAUSA:-1}
ETAPAS=(gitleaks kics osv semgrep zap)

titulo() { printf '\n\033[1;36m━━ %s ━━\033[0m\n' "$*"; }
pausa() {
  if [ "$PAUSA" = 1 ]; then
    read -rp $'\n\033[1;33m⏸  Pausa. Enter para continuar (Ctrl+C para salir)...\033[0m'
  fi
}

# Mismo criterio que el job de CI: tabla de severidades y decisión de bloqueo.
evaluar() {
  local herramienta=$1 reporte=$2 n
  if [ ! -s "$reporte" ]; then
    echo "✗ No se generó $reporte. Plan B: abre demo/respaldo/$rama/" | tee -a "$OUT/resumen.md"
    return
  fi
  "$H/politica.sh" resumen "$herramienta" "$reporte" | tee -a "$OUT/resumen.md"
  n=$("$H/politica.sh" bloqueantes "$herramienta" "$reporte")
  if [ "$herramienta" = zap ]; then
    printf '\033[1;34mℹ zap: solo reporta, no bloquea (en CI corre solo si las 4 etapas estáticas pasan)\033[0m\n'
    echo "**Resultado: ℹ solo reporta**" >> "$OUT/resumen.md"
  elif [ "$n" -gt 0 ]; then
    printf '\033[1;31m✗ %s: %s hallazgo(s) rompen el build\033[0m\n' "$herramienta" "$n"
    echo "**Resultado: ✗ rompe el build ($n)**" >> "$OUT/resumen.md"
  else
    printf '\033[1;32m✓ %s: pasa la política\033[0m\n' "$herramienta"
    echo "**Resultado: ✓ pasa**" >> "$OUT/resumen.md"
  fi
  echo >> "$OUT/resumen.md"
}

preparar() {
  for n in gitleaks kics osv semgrep zap juice-shop; do
    titulo "docker pull $n"
    docker pull "$(img "$n")"
  done
}

gitleaks() {
  titulo "1/5 Secretos · Gitleaks (historial completo de git)"
  docker run --rm "${YO[@]}" -v "$PWD:/repo" -w /repo "$(img gitleaks)" \
    git /repo --redact --no-banner --exit-code 0 -v \
    --report-format sarif --report-path "/repo/$OUT/gitleaks.sarif"
  evaluar gitleaks "$OUT/gitleaks.sarif"
}

kics() {
  titulo "2/5 IaC · KICS (infra/)"
  docker run --rm "${YO[@]}" -v "$PWD:/repo" "$(img kics)" scan \
    -p /repo/infra -o "/repo/$OUT" --output-name kics \
    --report-formats json,sarif,html --ignore-on-exit results \
    --disable-secrets --no-progress
  evaluar kics "$OUT/kics.json"
}

osv() {
  titulo "3/5 Dependencias · OSV-Scanner (app/package-lock.json)"
  docker run --rm "${YO[@]}" -v "$PWD:/repo" -w /repo "$(img osv)" \
    scan source -r app --format table
  docker run --rm "${YO[@]}" -v "$PWD:/repo" -w /repo "$(img osv)" \
    scan source -r app --format json --output "$OUT/osv.json" >/dev/null 2>&1
  docker run --rm "${YO[@]}" -v "$PWD:/repo" -w /repo "$(img osv)" \
    scan source -r app --format sarif --output "$OUT/osv.sarif" >/dev/null 2>&1
  evaluar osv "$OUT/osv.json"
}

semgrep() {
  titulo "4/5 Código · Semgrep CE (app/src)"
  docker run --rm "${YO[@]}" -v "$PWD:/src" -w /src "$(img semgrep)" semgrep scan \
    --config p/javascript --config p/expressjs --config p/nodejsscan \
    --metrics=off --sarif-output="$OUT/semgrep.sarif" --json-output="$OUT/semgrep.json" \
    app/src
  evaluar semgrep "$OUT/semgrep.json"
}

zap() {
  titulo "5/5 DAST · ZAP baseline contra OWASP Juice Shop"
  docker rm -f vsandbox-juice >/dev/null 2>&1
  docker run -d --name vsandbox-juice -p 127.0.0.1:3000:3000 "$(img juice-shop)" >/dev/null
  echo "Esperando a Juice Shop en http://localhost:3000 ..."
  for _ in $(seq 60); do curl -sf http://localhost:3000 >/dev/null && break; sleep 2; done

  local wrk="$OUT/zap" cfg=()
  mkdir -p "$wrk" && chmod 777 "$wrk" && cp .zap/* "$wrk/"
  [ -f "$wrk/rules.tsv" ] && cfg=(-c rules.tsv)
  docker run --rm --network host -v "$PWD/$wrk:/zap/wrk:rw" "$(img zap)" \
    zap-baseline.py -t http://localhost:3000 "${cfg[@]}" -I \
    -J zap.json -r zap.html -w zap.md --hook=/zap/wrk/sarif_hook.py
  docker rm -f vsandbox-juice >/dev/null
  evaluar zap "$wrk/zap.json"
  echo "Reporte HTML: $wrk/zap.html"
}

if [ "${1:-}" = preparar ]; then preparar; exit; fi

[ $# -gt 0 ] && ETAPAS=("$@")
mkdir -p "$OUT"
# shellcheck disable=SC2016 # las comillas invertidas son Markdown
printf '# Resultados en rama `%s` (%s)\n\n' "$rama" "$(date '+%Y-%m-%d %H:%M')" > "$OUT/resumen.md"

for e in "${ETAPAS[@]}"; do
  "$e"
  pausa
done

titulo "Resumen guardado en $OUT/resumen.md"
