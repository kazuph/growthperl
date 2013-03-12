#!/bin/sh
cpanm Carton
# plenv
if [ -d ${HOME}/.plenv  ] ; then
    plenv rehash
fi

carton install
# cpanm -Lextlib -n --installdeps .

cpanm Test::Pretty
cpanm Proclet

# plenv
if [ -d ${HOME}/.plenv  ] ; then
    plenv rehash
fi
