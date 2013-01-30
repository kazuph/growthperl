#!/bin/sh
echo "setup database"
if [ ! -d db ]
then
    echo "make dir db"
    mkdir db
fi
sqlite3 db/deployment.db < sql/sqlite.sql
