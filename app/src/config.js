// Configuración de la app.
// HALLAZGO PLANTADO (Gitleaks): token FALSO con formato de GitHub PAT.
// No es una credencial real; existe solo para que Gitleaks lo detecte.
module.exports = {
  port: process.env.PORT || 3000,
  githubToken: "ghp_EiqQnww4tCi8O2AHRt7IZmcWWFPrr9acXVV1",
};
