#!/bin/sh
# perl -Mlib=extlib/lib/perl5 extlib/bin/plackup -s Starman -E development --preload-app --disable-keepalive --workers 2 app.psgi -r
# carton exec -Ilib -- starman -E development --preload-app --disable-keepalive --workers 2 app.psgi -r
proclet start --color
