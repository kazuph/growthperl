BEGIN TRANSACTION;

CREATE TABLE IF NOT EXISTS entry (
  id INTEGER PRIMARY KEY AUTOINCREMENT, 
  entry_id varchar(36) NOT NULL,
  body longblob NOT NULL,
  run_time text NOT NULL,
  result text unsigned NOT NULL,
  ctime int unsigned NOT NULL
);

COMMIT;