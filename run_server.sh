#!/bin/sh
perl -Mlib=extlib/lib/perl5 extlib/bin/plackup -s Starman -E deployment --preload-app --disable-keepalive --workers 10 app.psgi
