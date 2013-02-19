use strict;
use warnings;
use utf8;
use File::Spec;
use File::Basename;
use lib File::Spec->catdir(dirname(__FILE__), 'extlib', 'lib', 'perl5');
use lib File::Spec->catdir(dirname(__FILE__), 'lib');
use Plack::Builder;

use GrowthPerl::Web;
use GrowthPerl;
use Plack::Session::Store::DBI;
use Plack::Session::State::Cookie;
use DBI;
use YAML::XS;
use Log::Minimal;
use Data::Dump qw/dump/;

{
    my $c = GrowthPerl->new();
    $c->setup_schema();
}

my $db_config = GrowthPerl->config->{DBI} || die "Missing configuration for DBI";
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
    # enable_if { $ENV{PLACK_ENV} ne 'development' } "Auth::Basic",  authenticator => \&authen_cb;
    enable "Auth::Basic", authenticator => \&authen_cb;
    enable 'AxsLog', response_time => 1, error_only => 0;
    enable 'Log::Minimal', autodump => 1;
    GrowthPerl::Web->to_app();
};

sub authen_cb {
    my($username, $password) = @_;

    # read users.yml
    my $users;
    my $basedir = File::Spec->rel2abs(File::Spec->catdir(dirname(__FILE__)));
    if ( -d "$basedir/config/users/") {
        $users = YAML::XS::LoadFile("$basedir/config/users/users.yml");
    }
    for my $user (keys %$users) {
        return 1 if $user eq $username and $$users{$user} eq $password;
    }
    return 0;
}
