#!/bin/sh
echo "setup database"
sqlite3 deployment.db < sql/sqlite.sql

