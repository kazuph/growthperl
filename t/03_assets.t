use strict;
use warnings;
use utf8;
use t::Util;
use Plack::Test;
use Plack::Util;
use Test::More;

my $app = Plack::Util::load_psgi 'app.psgi';
test_psgi
    app => $app,
    client => sub {
        my $cb = shift;
        for my $fname (qw(
            static/css/bootstrap.min.css
            static/css/bootstrap-responsive.min.css
            static/css/main.css
            static/js/jquery-1.5.1.min.js
            static/js/google-code-prettify/prettify.css
            static/js/google-code-prettify/prettify.js
            robots.txt
            )) {
            my $req = HTTP::Request->new(GET => "http://localhost/$fname");
            my $res = $cb->($req);
            is($res->code, 200, $fname) or diag $res->content;
        }
    };

done_testing;
