#!/bin/sh
# cpanm Module::CoreList
# wait
cpanm -Lextlib -n --installdeps .
# wait
# perl -Mlib=extlib/lib/perl5 extlib/bin/plackup -s Starman -E production --preload-app app.psgi

