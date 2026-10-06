// Configuración de la app.
// CORREGIDO: el token se inyecta en tiempo de ejecución, nunca va en el código.
module.exports = {
  port: process.env.PORT || 3000,
  githubToken: process.env.GITHUB_TOKEN,
};
