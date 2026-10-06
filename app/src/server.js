const express = require("express");
const { execFile } = require("child_process");
const _ = require("lodash");
const db = require("./db");
const config = require("./config");

const app = express();
app.use(express.json());

// CORREGIDO: consulta parametrizada; el motor trata id como dato, nunca como SQL.
app.get("/users", (req, res) => {
  const rows = db.prepare("SELECT id, name, email FROM users WHERE id = ?").all(Number(req.query.id));
  res.json(rows);
});

// CORREGIDO: lista blanca del host y execFile sin shell; ";" ya no encadena comandos.
const HOST = /^[a-zA-Z0-9.-]{1,253}$/;
app.get("/ping", (req, res) => {
  const host = String(req.query.host || "");
  if (!HOST.test(host)) return res.status(400).send("host inválido");
  execFile("ping", ["-c", "1", host], (err, stdout) => {
    if (err) return res.status(500).send("error");
    res.type("text").send(stdout);
  });
});

// CORREGIDO: sin eval. Solo se aceptan operaciones aritméticas simples.
const OPS = { "+": (a, b) => a + b, "-": (a, b) => a - b, "*": (a, b) => a * b, "/": (a, b) => a / b };
const EXPR = /^\s*(-?\d+(?:\.\d+)?)\s*([+\-*/])\s*(-?\d+(?:\.\d+)?)\s*$/;
app.post("/calc", (req, res) => {
  const m = String(req.body.expr || "").match(EXPR);
  if (!m) return res.status(400).json({ error: "expresión no soportada" });
  res.json({ result: OPS[m[2]](Number(m[1]), Number(m[3])) });
});

// CORREGIDO: lodash actualizado (CVE-2021-23337) y respuesta JSON en vez de HTML.
app.get("/hello", (req, res) => {
  const tpl = _.template("Hola, <%- name %>");
  res.json({ saludo: tpl({ name: req.query.name || "V-SandBox" }) });
});

app.get("/health", (req, res) => res.json({ status: "ok" }));

app.listen(config.port, () => {
  console.log(`Escuchando en :${config.port}`);
});
