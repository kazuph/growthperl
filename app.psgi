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
use Plack::Session::Store::DBI;
use Plack::Session::State::Cookie;
use DBI;

{
    my $c = PerlPad->new();
    $c->setup_schema();
}
my $db_config = PerlPad->config->{DBI} || die "Missing configuration for DBI";
builder {
    enable 'Plack::Middleware::Static',
    path => qr{^(?:/static/)},
    root => File::Spec->catdir(dirname(__FILE__));
    enable 'Plack::Middleware::Static',
    path => qr{^(?:/robots\.txt|/favicon\.ico)$},
    root => File::Spec->catdir(dirname(__FILE__), 'static');
    enable 'Plack::Middleware::ReverseProxy';
    enable 'Plack::Middleware::Session',
        store => Plack::Session::Store::DBI->new(
            get_dbh => sub {
                DBI->connect( @$db_config )
                    or die $DBI::errstr;
            }
        ),
        state => Plack::Session::State::Cookie->new(
            httponly => 1,
        );
    enable "Auth::Basic",  authenticator => \&authen_cb;
    enable 'AxsLog', response_time => 1, error_only => 0;
    PerlPad::Web->to_app();
};

sub authen_cb {
    my($username, $password) = @_;
    return $username eq 'admin' && $password eq 'admin';
}
