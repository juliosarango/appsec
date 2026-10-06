# Pipeline de seguridad aplicativa con herramientas open source

Demo de la charla de **V-SandBox**: un pipeline de GitHub Actions que protege el código desde el commit hasta la aplicación corriendo. No usa cuentas ni tokens externos: el único token es el `GITHUB_TOKEN` del propio workflow.

- Rama `main`: la app trae hallazgos plantados y el pipeline **falla**.
- Rama `fix`: los hallazgos están corregidos y el pipeline **pasa**.

## Etapas

| Etapa | Herramienta | Qué hace | Rompe el build |
|---|---|---|---|
| Secretos | [Gitleaks](https://github.com/gitleaks/gitleaks) | Busca credenciales en **todo el historial** de git. | Con cualquier secreto |
| IaC | [KICS](https://github.com/Checkmarx/kics) | Revisa `infra/Dockerfile` y `infra/docker-compose.yml`. | Con severidad alta o crítica |
| SCA | [OSV-Scanner](https://github.com/google/osv-scanner) | Cruza `package-lock.json` con la base OSV. | Con CVSS ≥ 7 |
| SAST | [Semgrep CE](https://github.com/semgrep/semgrep) | Busca inyecciones y `eval` en `app/src` con reglas públicas. | Con severidad alta (`ERROR`) |
| DAST | [ZAP baseline](https://www.zaproxy.org/docs/docker/baseline-scan/) | Escaneo pasivo contra [OWASP Juice Shop](https://owasp.org/www-project-juice-shop/). | No: solo reporta |

Las cuatro primeras corren en paralelo. ZAP corre solo si las cuatro pasan. Todas suben SARIF a **Security → Code scanning**, cada una con su propia categoría. La política de bloqueo está en un solo archivo, [`.github/herramientas/politica.sh`](.github/herramientas/politica.sh), que comparten el CI y la ejecución local.

## Replicarlo en tu fork

1. Haz fork **con todas las ramas** (desmarca "Copy the `main` branch only").
2. En **Actions**, habilita los workflows: GitHub los desactiva en los forks.
3. Deja el repo **público**. Code scanning es gratis en repos públicos; en uno privado necesitas GitHub Advanced Security.
4. Lanza **Actions → appsec → Run workflow** en `main` y luego en `fix`.

## Ejecutarlo en local

Solo necesitas Docker, `git`, `jq` y `curl`. El script usa las mismas imágenes, fijadas por digest, que el pipeline.

```bash
demo/demo.sh preparar        # descarga las imágenes (ZAP pesa ~2.4 GB)
demo/demo.sh                 # las cinco etapas, con pausa entre cada una
demo/demo.sh kics semgrep    # solo algunas
PAUSA=0 demo/demo.sh         # sin pausas
```

Los reportes quedan en `reportes/<rama>/`. En [`demo/respaldo/`](demo/respaldo/) hay reportes ya generados de las dos ramas por si algo falla en vivo. El guion de la demo, con los puntos de pausa y el plan B de cada etapa, está en [`docs/guion-demo.md`](docs/guion-demo.md).

<details>
<summary>Comandos de cada herramienta, sin el script</summary>

```bash
img() { .github/herramientas/imagen.sh "$1"; }   # imprime la imagen fijada por digest

# Secretos (historial completo)
docker run --rm -v "$PWD:/repo" -w /repo "$(img gitleaks)" git /repo --redact -v

# IaC
docker run --rm -v "$PWD:/repo" "$(img kics)" scan -p /repo/infra -o /repo/reportes --disable-secrets

# Dependencias
docker run --rm -v "$PWD:/repo" -w /repo "$(img osv)" scan source -r app

# Código
docker run --rm -v "$PWD:/src" -w /src "$(img semgrep)" semgrep scan \
  --config p/javascript --config p/expressjs --config p/nodejsscan --metrics=off app/src

# DAST
docker run -d --name juice -p 127.0.0.1:3000:3000 "$(img juice-shop)"
docker run --rm --network host "$(img zap)" zap-baseline.py -t http://localhost:3000 -I
docker rm -f juice
```
</details>

## Comparar `main` y `fix`

```bash
git diff main fix              # todas las correcciones: es un solo commit
git diff main fix -- infra/    # solo una etapa
```

Para verlo en el pipeline, abre un pull request de `fix` hacia `main`: el PR lanza las cinco etapas y debe salir en verde.

`fix` también trae dos **excepciones justificadas**, cada una con su motivo (en las dos ramas, [`.gitleaks.toml`](.gitleaks.toml) además excluye los reportes generados de `demo/respaldo/`):

- [`.gitleaksignore`](.gitleaksignore): el token falso se borró del código, pero sigue en el historial de git. La excepción se fija por fingerprint (commit, archivo, regla y línea), así que un secreto nuevo vuelve a romper el build.
- [`.zap/rules.tsv`](.zap/rules.tsv): la regla 10110 marca código del bundle de Juice Shop, que no es nuestro.

## Por qué fijamos por SHA

Un tag como `@v1` o `:latest` es un puntero que se puede mover. Si alguien toma control del repo o de la cuenta del registro, mueve el tag a código malicioso y tu pipeline lo ejecuta sin que cambies una línea.

- **19 de marzo de 2026, Trivy (CVE-2026-33634).** Unos atacantes reescribieron 75 de los 76 tags de `aquasecurity/trivy-action` para que apuntaran a un stealer de credenciales. Wiz reportó un compromiso paralelo de `checkmarx/kics-github-action`.
- **22 de abril de 2026, KICS en Docker Hub.** Con credenciales válidas del publicador, sobrescribieron los tags `v2.1.20`, `alpine` y `latest` de `checkmarx/kics` y crearon un `v2.1.21` falso. El binario modificado enviaba los resultados del escaneo a un servidor de los atacantes. Este repo usa `v2.1.20-alpine` con el digest publicado el 3 de marzo, que no está entre los digests maliciosos que publicó Checkmarx.

Por eso en [`docs/workflow-inseguro.yml`](docs/workflow-inseguro.yml) (no se ejecuta) se ve lo que **no** hay que hacer, y en [`appsec.yml`](.github/workflows/appsec.yml):

1. Cada acción se referencia por el SHA completo del commit, con el tag como comentario.
2. Cada imagen se referencia por digest, en [`.github/herramientas/Dockerfile`](.github/herramientas/Dockerfile).
3. `permissions: contents: read` a nivel de workflow; solo los jobs que suben SARIF tienen `security-events: write`.
4. `persist-credentials: false` en `actions/checkout`.
5. Las imágenes de las herramientas están en un Dockerfile y no dentro de un `docker run`, para que un bot de actualización pueda encontrarlas (ver [Consejos finales](#consejos-finales)).

Fijar por SHA tiene límites. `google/osv-scanner-action` usa por dentro `ghcr.io/google/osv-scanner-action:v2.6.0` **por tag**, así que fijar la acción no fija esa imagen. Revisa también lo que ejecutan tus dependencias.

Fuentes:

- Wiz Research: https://www.wiz.io/es-es/blog/trivy-compromised-teampcp-supply-chain-attack
- Snyk, línea de tiempo: https://snyk.io/es/articles/trivy-github-actions-supply-chain-compromise/
- Alerta NHS CC-4758 (CVE-2026-33634): https://nhsd-proxy.openprescribing.net/cyber-alerts/2026/cc-4758
- Socket, indicadores de compromiso: https://socket.dev/supply-chain-attacks/trivy-github-actions-compromise
- Advisory oficial: repositorio `aquasecurity/trivy` en GitHub, sección Security Advisories.
- Checkmarx, incidente de KICS en Docker Hub: https://checkmarx.com/blog/ongoing-security-updates/
- Docker, "Trivy, KICS, and the shape of supply chain attacks so far in 2026": https://www.docker.com/blog/trivy-kics-and-the-shape-of-supply-chain-attacks-so-far-in-2026/

## Por qué estas herramientas y no otras

- **Snyk:** tiene plan gratuito, pero exige cuenta y token, y es un producto comercial.
- **Trivy:** se usa aquí como caso de estudio, no como herramienta.
- **SonarQube Community Build:** no hace taint analysis, así que no detecta inyecciones por flujo de datos. Además necesita un servidor y no analiza ramas ni pull requests.

## Consejos finales

**Fijar por SHA sin un bot que actualice te deja congelado.** Tarde o temprano usarás una versión con un CVE conocido. Elige un bot según tu plataforma:

- **Dependabot** viene incluido en GitHub. En este repo está **desactivado a propósito**, para que no corrija `main` antes de la demo. El ejemplo está en [`docs/dependabot.yml`](docs/dependabot.yml); para activarlo, cópialo a `.github/dependabot.yml`. Las alertas de dependencias vulnerables se activan aparte, en **Settings → Code security**.
- **[Renovate](https://github.com/renovatebot/renovate)** es open source y funciona en GitHub, GitLab, Bitbucket y Azure DevOps. Úsalo si tu equipo no está en GitHub.

Cualquiera de los dos solo te avisa de que existe una versión nueva, no de que sea segura. Si un atacante publica una versión maliciosa, el bot te la propone igual. Por eso cada PR pasa por el pipeline y por una revisión humana, y no se mezcla automáticamente.

> ⚠️ El token de `app/src/config.js` en `main` es **falso**: solo tiene el formato de un GitHub PAT. La app de `main` es vulnerable a propósito; no la despliegues.
