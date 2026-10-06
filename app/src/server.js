const express = require("express");
const { exec } = require("child_process");
const _ = require("lodash");
const db = require("./db");
const config = require("./config");

const app = express();
app.use(express.json());

// HALLAZGO PLANTADO (SAST): inyección SQL por concatenación.
// Prueba: /users?id=1 OR 1=1
app.get("/users", (req, res) => {
  const rows = db.prepare("SELECT id, name, email FROM users WHERE id = " + req.query.id).all();
  res.json(rows);
});

// HALLAZGO PLANTADO (SAST): inyección de comandos.
// Prueba: /ping?host=127.0.0.1;id
app.get("/ping", (req, res) => {
  exec(`ping -c 1 ${req.query.host}`, (err, stdout) => {
    if (err) return res.status(500).send("error");
    res.type("text").send(stdout);
  });
});

// HALLAZGO PLANTADO (SAST): eval sobre entrada del usuario.
// Prueba: POST /calc {"expr":"require('fs').readdirSync('/')"}
app.post("/calc", (req, res) => {
  const result = eval(req.body.expr);
  res.json({ result });
});

// Usa lodash.template, afectado por CVE-2021-23337 en lodash < 4.17.21.
app.get("/hello", (req, res) => {
  const tpl = _.template("Hola, <%- name %>");
  res.send(tpl({ name: req.query.name || "V-SandBox" }));
});

app.get("/health", (req, res) => res.json({ status: "ok" }));

app.listen(config.port, () => {
  console.log(`Escuchando en :${config.port}`);
});
