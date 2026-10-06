# Resultados en rama `main` (2026-10-05 22:45)

### Gitleaks

| Secretos |
|---|
| 1 |

<details><summary>Ver 1 hallazgo(s)</summary>

| Severidad | Hallazgo | Ubicación |
|---|---|---|
| Secreto | github-pat | `app/src/config.js:6 (commit 3bcb78f)` |

</details>

**Resultado: ✗ rompe el build (1)**

### KICS

| Crítica | Alta | Media | Baja | Info |
|---|---|---|---|---|
| 0 | 2 | 6 | 2 | 0 |

<details><summary>Ver 10 hallazgo(s)</summary>

| Severidad | Hallazgo | Ubicación |
|---|---|---|
| HIGH | Missing User Instruction | `infra/Dockerfile:5` |
| HIGH | Privileged Containers Enabled | `infra/docker-compose.yml:8` |
| MEDIUM | Container Capabilities Unrestricted | `infra/docker-compose.yml:3` |
| MEDIUM | Container Traffic Not Bound To Host Interface | `infra/docker-compose.yml:9` |
| MEDIUM | Healthcheck Not Set | `infra/docker-compose.yml:3` |
| MEDIUM | Image Version Using 'latest' | `infra/Dockerfile:5` |
| MEDIUM | Privileged Ports Mapped In Container | `infra/docker-compose.yml:9` |
| MEDIUM | Security Opt Not Set | `infra/docker-compose.yml:3` |
| LOW | Exposing Port 22 (SSH) | `infra/Dockerfile:11` |
| LOW | Healthcheck Instruction Missing | `infra/Dockerfile:5` |

</details>

**Resultado: ✗ rompe el build (2)**

### OSV-Scanner

| Crítica | Alta | Media | Baja | Sin CVSS |
|---|---|---|---|---|
| 0 | 1 | 2 | 0 | 0 |

<details><summary>Ver 3 hallazgo(s)</summary>

| Severidad | Hallazgo | Ubicación |
|---|---|---|
| CVSS 8.1 | lodash@4.17.20: CVE-2021-23337, CVE-2026-4800 | `app/package-lock.json` |
| CVSS 6.9 | lodash@4.17.20: CVE-2025-13465, CVE-2026-2950 | `app/package-lock.json` |
| CVSS 5.3 | lodash@4.17.20: CVE-2020-28500 | `app/package-lock.json` |

</details>

**Resultado: ✗ rompe el build (1)**

### Semgrep

| Alta (ERROR) | Media (WARNING) | Baja (INFO) |
|---|---|---|
| 5 | 1 | 0 |

<details><summary>Ver 6 hallazgo(s)</summary>

| Severidad | Hallazgo | Ubicación |
|---|---|---|
| ERROR | tainted-sql-string | `app/src/server.js:13` |
| ERROR | generic_os_command_exec | `app/src/server.js:20` |
| ERROR | eval_nodejs | `app/src/server.js:29` |
| ERROR | code-string-concat | `app/src/server.js:29` |
| ERROR | express_xss | `app/src/server.js:36` |
| WARNING | direct-response-write | `app/src/server.js:36` |

</details>

**Resultado: ✗ rompe el build (5)**

### ZAP baseline (no bloquea)

| Alta | Media | Baja | Info | Ignoradas (rules.tsv) |
|---|---|---|---|---|
| 0 | 2 | 5 | 4 | 0 |

<details><summary>Ver 11 hallazgo(s)</summary>

| Severidad | Hallazgo | Ubicación |
|---|---|---|
| Medium | Content Security Policy (CSP) Header Not Set [10038] | `ej.: http://localhost:3000` |
| Medium | Cross-Domain Misconfiguration [10098] | `ej.: http://localhost:3000/` |
| Low | Cross-Origin-Embedder-Policy Header Missing or Invalid [90004] | `ej.: http://localhost:3000` |
| Low | Cross-Origin-Opener-Policy Header Missing or Invalid [90004] | `ej.: http://localhost:3000` |
| Low | Dangerous JS Functions [10110] | `ej.: http://localhost:3000/main.js` |
| Low | Deprecated Feature Policy Header Set [10063] | `ej.: http://localhost:3000` |
| Low | Timestamp Disclosure - Unix [10096] | `ej.: http://localhost:3000/` |
| Informational | Modern Web Application [10109] | `ej.: http://localhost:3000` |
| Informational | Non-Storable Content [10049] | `ej.: http://localhost:3000/ftp/encrypt.pyc` |
| Informational | Storable and Cacheable Content [10049] | `ej.: http://localhost:3000/robots.txt` |
| Informational | Storable but Non-Cacheable Content [10049] | `ej.: http://localhost:3000` |

</details>

**Resultado: ℹ solo reporta**

