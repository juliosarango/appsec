# NO SE CONSTRUYE. Es la lista de imágenes de las herramientas del pipeline.
# Vive en un Dockerfile para que un bot de actualización (Dependabot, Renovate)
# lo detecte y proponga tags y digests nuevos; el workflow y demo/demo.sh leen las líneas FROM.

FROM ghcr.io/gitleaks/gitleaks:v8.30.1@sha256:c00b6bd0aeb3071cbcb79009cb16a60dd9e0a7c60e2be9ab65d25e6bc8abbb7f AS gitleaks

# v2.1.20-alpine con el digest publicado el 2026-03-03, antes del compromiso
# de Docker Hub del 2026-04-22. Los tags v2.1.20, alpine y latest fueron reescritos.
FROM checkmarx/kics:v2.1.20-alpine@sha256:990ae994fbbe59760c8e4f7e89b1193a39a0c2968909058ec29335cb6d80efc1 AS kics

# Solo para ejecución local: en CI la acción oficial usa su propia imagen.
FROM ghcr.io/google/osv-scanner:v2.6.0@sha256:afd838850ac1a0fcc15ff4a041dc9ba11123c3f0d2666217a5f0fcf9222b55fa AS osv

FROM semgrep/semgrep:1.179.0@sha256:93963d9295a366f59e4850127b1550400ee7b388f04fe144e4a1f6325d96e01b AS semgrep

FROM ghcr.io/zaproxy/zaproxy:2.17.0@sha256:781a2bdaea47324e7bab583e2263f21d257b0aee61ed51521a5be45f5f5081ef AS zap

# Objetivo del DAST. En el workflow va duplicada en services (ahí no se puede leer
# un archivo); mantén ambas iguales.
FROM bkimminich/juice-shop:v20.2.0@sha256:8739101ade29358abb5469ee66ae78e582c97ed0a5543a4ad102e5fa5193526b AS juice-shop
