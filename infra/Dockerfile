# CORREGIDO (estado "después" de la demo).
# Base fijada por digest: el build es reproducible y Dependabot propone las actualizaciones.
FROM node:24-alpine3.22@sha256:191c9f0080fcbbc6547a85dc0ff7988072214a355aabdc1d2ec55a7dae5eea8a

ENV NODE_ENV=production
WORKDIR /app

# Solo dependencias de producción, exactamente las del lockfile.
COPY app/package.json app/package-lock.json ./
RUN npm ci --omit=dev --ignore-scripts && npm cache clean --force
COPY app/src ./src

# Usuario sin privilegios que ya trae la imagen oficial de Node.
USER node

EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD wget -qO- http://127.0.0.1:3000/health || exit 1
CMD ["node", "src/server.js"]
