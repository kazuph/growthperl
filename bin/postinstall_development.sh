#!/bin/sh

echo "setup database"
sqlite3 development.db < sql/sqlite.sql

