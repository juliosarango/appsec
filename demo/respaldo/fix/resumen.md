# Resultados en rama `fix` (2026-10-05 22:46)

### Gitleaks

| Secretos |
|---|
| 0 |

**Resultado: ✓ pasa**

### KICS

| Crítica | Alta | Media | Baja | Info |
|---|---|---|---|---|
| 0 | 0 | 0 | 0 | 0 |

**Resultado: ✓ pasa**

### OSV-Scanner

| Crítica | Alta | Media | Baja | Sin CVSS |
|---|---|---|---|---|
| 0 | 0 | 0 | 0 | 0 |

**Resultado: ✓ pasa**

### Semgrep

| Alta (ERROR) | Media (WARNING) | Baja (INFO) |
|---|---|---|
| 0 | 0 | 0 |

**Resultado: ✓ pasa**

### ZAP baseline (no bloquea)

| Alta | Media | Baja | Info | Ignoradas (rules.tsv) |
|---|---|---|---|---|
| 0 | 2 | 4 | 3 | 1 |

<details><summary>Ver 10 hallazgo(s)</summary>

| Severidad | Hallazgo | Ubicación |
|---|---|---|
| Medium | Content Security Policy (CSP) Header Not Set [10038] | `ej.: http://localhost:3000` |
| Medium | Cross-Domain Misconfiguration [10098] | `ej.: http://localhost:3000` |
| Low | Cross-Origin-Embedder-Policy Header Missing or Invalid [90004] | `ej.: http://localhost:3000` |
| Low | Cross-Origin-Opener-Policy Header Missing or Invalid [90004] | `ej.: http://localhost:3000` |
| Low | Dangerous JS Functions [10110] (ignorada) | `ej.: http://localhost:3000/main.js` |
| Low | Deprecated Feature Policy Header Set [10063] | `ej.: http://localhost:3000` |
| Low | Timestamp Disclosure - Unix [10096] | `ej.: http://localhost:3000` |
| Informational | Modern Web Application [10109] | `ej.: http://localhost:3000` |
| Informational | Storable and Cacheable Content [10049] | `ej.: http://localhost:3000/robots.txt` |
| Informational | Storable but Non-Cacheable Content [10049] | `ej.: http://localhost:3000` |

</details>

**Resultado: ℹ solo reporta**

