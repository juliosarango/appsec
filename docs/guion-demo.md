# Guion de la demo en vivo

Todo se ejecuta en vivo. Cada etapa tiene un **punto de pausa** (⏸) para explicar y un **plan B** por si algo falla. Los planes B no dependen de internet: los reportes ya generados están en `demo/respaldo/`.

## Antes de la charla (el día anterior)

1. Hacer push de `main` y `fix` y esperar a que las dos ejecuciones de Actions terminen. **Guardar los enlaces** de ambas ejecuciones: son el plan B del pipeline completo.
2. Revisar que la pestaña **Security → Code scanning** muestre alertas de las cuatro categorías estáticas (`gitleaks`, `kics`, `osv-scanner`, `semgrep`), y que la ejecución de `fix` tenga el artifact `zap-report`.
3. Descargar las imágenes (ZAP pesa ~2.4 GB):
   ```bash
   demo/demo.sh preparar
   ```
4. Ensayo completo sin pausas en las dos ramas: `PAUSA=0 demo/demo.sh` (~70 s por rama).
5. Dejar abiertas estas pestañas: el repo, la ejecución verde, la ejecución roja, Security, y los archivos `demo/respaldo/main/kics.html` y `demo/respaldo/fix/zap/zap.html`.

## Recorrido

| # | Qué mostrar | Comando o lugar | ⏸ Punto de pausa: qué explicar | Plan B |
|---|---|---|---|---|
| 0 | El caso Trivy | `docs/workflow-inseguro.yml` frente a `.github/workflows/appsec.yml` | Tag mutable frente a SHA. `permissions` y `persist-credentials`. KICS: acción comprometida en marzo e imagen de Docker Hub reescrita en abril. | Diapositivas |
| 1 | Secretos | `git switch main && demo/demo.sh gitleaks` | Gitleaks recorre **todo el historial**. `--redact` evita que el valor quede en logs y SARIF. | `cat demo/respaldo/main/consola.log` |
| 2 | IaC | `demo/demo.sh kics` | Dos HIGH: falta `USER` y `privileged: true`. `latest` y la falta de `HEALTHCHECK` son medias: se reportan, pero no rompen el build. | `demo/respaldo/main/kics.html` |
| 3 | Dependencias | `demo/demo.sh osv` | lodash 4.17.20: OSV agrupa CVE-2021-23337 (CVSS 7.2) y CVE-2026-4800 (8.1), ambos de inyección en `_.template`. La política usa el CVSS más alto del grupo, no el código de salida de la herramienta. | `demo/respaldo/main/osv.json` |
| 4 | Código | `demo/demo.sh semgrep` | SQLi y `eval` por flujo de datos. Contar los dos casos raros (abajo). | `demo/respaldo/main/semgrep.json` |
| 5 | El pipeline rojo | Pestaña Actions, ejecución de `main` | Las cuatro etapas fallan en paralelo y ZAP no corre (`needs`). Mostrar el resumen de cada job y la pestaña Security. | Enlace guardado |
| 6 | La corrección | `git diff main fix` | Un commit, una corrección por hallazgo. | Mismo comando: no depende de la red |
| 7 | Excepciones | `.gitleaksignore` y `.zap/rules.tsv` en `fix` | El secreto se borró del código, pero sigue en el historial. La excepción se fija por fingerprint y lleva el motivo. | Mostrar solo los archivos |
| 8 | Pipeline verde | Abrir un PR `fix → main` o lanzar **Run workflow** en `fix` | El PR dispara el pipeline completo. ZAP corre contra Juice Shop y reporta sin bloquear. | Enlace de la ejecución verde |
| 9 | DAST | `git switch fix && demo/demo.sh zap` | Baseline es pasivo. `IGNORE: 1` es la excepción documentada. ZAP no aparece en Security: Code scanning rechaza ubicaciones `http://` (solo acepta archivos del repo), así que su reporte va como artifact. | `demo/respaldo/fix/zap/zap.html` |

## Dos falsos negativos/positivos que vale la pena contar

- **Falso negativo:** con `require("node:child_process")`, la regla de inyección de comandos de njsscan **no** detecta el `exec`; con `require("child_process")` sí. Por eso la app usa la segunda forma. Las reglas son patrones: no garantizan cobertura.
- **Falso positivo:** en `fix`, `EXPR.exec(...)` (una `RegExp`) se reportaba como ejecución de comandos del sistema. Se cambió a `String.match()`. Conviene revisar un hallazgo antes de declararlo un riesgo.

## Si algo falla en vivo

| Síntoma | Qué hacer |
|---|---|
| Sin internet o Docker Hub/GHCR lentos | Si las imágenes ya están descargadas, todo funciona sin red **menos Semgrep**, que baja las reglas de semgrep.dev. Usar `demo/respaldo/`. |
| Semgrep no descarga las reglas | `cat demo/respaldo/main/consola.log` y abrir `semgrep.json` |
| Juice Shop no arranca a tiempo | `docker logs vsandbox-juice`. Si no se recupera en un minuto: `demo/respaldo/fix/zap/zap.html` |
| Puerto 3000 ocupado | `docker rm -f vsandbox-juice`, o liberar el puerto |
| Actions con cola larga o caído | Usar los enlaces de las ejecuciones del día anterior |
| La etapa se cuelga | Ctrl+C y correr solo la siguiente: `demo/demo.sh <etapa>` |

Para regenerar el respaldo después de cambiar algo:

```bash
for b in main fix; do git switch "$b"; PAUSA=0 demo/demo.sh | tee "reportes/$b/consola.log"; done
# luego copiar reportes/<rama>/ a demo/respaldo/<rama>/ (sin __pycache__, sarif_hook.py ni rules.tsv)
```
