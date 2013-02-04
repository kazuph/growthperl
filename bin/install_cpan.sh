#!/bin/sh
cpanm carton
carton install
# cpanm -Lextlib -n --installdeps .
cpanm Test::Pretty
cpanm Proclet
