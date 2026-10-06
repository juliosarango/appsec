const { DatabaseSync } = require("node:sqlite");

const db = new DatabaseSync(":memory:");
db.exec(`
  CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, email TEXT);
  INSERT INTO users (name, email) VALUES
    ('Ada', 'ada@example.com'),
    ('Linus', 'linus@example.com');
`);

module.exports = db;
