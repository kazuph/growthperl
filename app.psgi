use strict;
use utf8;
use File::Spec;
use File::Basename;
use lib File::Spec->catdir(dirname(__FILE__), 'extlib', 'lib', 'perl5');
use lib File::Spec->catdir(dirname(__FILE__), 'lib');
use Log::Minimal;
use Plack::Builder;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/extlib/lib/perl5";

use PerlPad::Web;
use PerlPad;
use DBI;

{
    my $c = PerlPad->new();
    $c->setup_schema();
}

builder {
    enable 'Plack::Middleware::Static',
    path => qr{^(?:/static/)},
    root => File::Spec->catdir(dirname(__FILE__));
    enable 'Plack::Middleware::Static',
    path => qr{^(?:/robots\.txt|/favicon\.ico)$},
    root => File::Spec->catdir(dirname(__FILE__), 'static');
    enable 'Plack::Middleware::ReverseProxy';
    enable "Plack::Middleware::AccessLog",  format => "combined";
    # enable "Plack::Middleware::AccessLog::Timed", 
    #           format => "%v %h %l %u %t \"%r\" %>s %b %D";
    # enable 'Debug';
    PerlPad::Web->to_app();
};
