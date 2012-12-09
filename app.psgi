use strict;
use utf8;
use File::Spec;
use File::Basename;
use lib File::Spec->catdir(dirname(__FILE__), 'extlib', 'lib', 'perl5');
use lib File::Spec->catdir(dirname(__FILE__), 'lib');
use Plack::Builder;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/extlib/lib/perl5";

use PerlPad::Web;
use PerlPad;
use DBI;
use Log::Minimal;

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
    enable "Plack::Middleware::Log::Minimal", autodump => 1;
    sub {
        my $env = shift;
        debugf("debug message");
        infof("infomation message");
        warnf("warning message");
        critf("critical message");
        ["200",[ 'Content-Type' => 'text/plain' ],["OK"]];
    };
    PerlPad::Web->to_app();
};
