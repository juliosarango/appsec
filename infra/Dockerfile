# INSEGURO A PROPÓSITO (estado "antes" de la demo).
# - Tag mutable "latest": no sabes qué imagen construyes mañana.
# - Corre como root: no hay instrucción USER.
# - Sin HEALTHCHECK.
FROM node:latest

WORKDIR /app
COPY app/ .
RUN npm install

EXPOSE 3000 22
CMD ["node", "src/server.js"]
