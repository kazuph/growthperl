#!/bin/sh
cpanm -Lextlib -n --installdeps .
cpanm Test::Pretty
