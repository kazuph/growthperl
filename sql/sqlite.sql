CREATE TABLE IF NOT EXISTS sessions (
    id CHAR(72) PRIMARY KEY,
    session_data TEXT
);

CREATE TABLE IF NOT EXISTS entry (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  body longblob NOT NULL,
  run_time text NOT NULL,
  result text unsigned NOT NULL,
  ctime int unsigned NOT NULL
);
