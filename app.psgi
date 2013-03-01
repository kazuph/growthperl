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
use Plack::Session::Store::Redis;
use Plack::Session::State::Cookie;
use Plack::Session::Store::Cache;
use Cache::Memcached::Fast;
use Data::MessagePack;
use DBI;
use YAML::XS;
use Log::Minimal;
use Data::Dump qw/dump/;
use Scope::Container::DBI;
use Scope::Container;

{
    my $c = GrowthPerl->new();
    $c->setup_schema();
}

my $db_config = GrowthPerl->config->{DBI} || die "Missing configuration for DBI";
builder {
    enable 'Plack::Middleware::Static',
    path => qr{^(?:/static/)},
    root => File::Spec->catdir(dirname(__FILE__));
    path => qr{^(?:/robots\.txt|/favicon\.ico)$},
    root => File::Spec->catdir(dirname(__FILE__), 'static');
    enable 'Plack::Middleware::ReverseProxy';
    # enable 'Session', store => 'Redis',
    # enable 'Session', store => Plack::Session::Store::Cache->new(
    #     cache => Cache::Memcached::Fast->new({
    #             servers => [{address => 'localhost:11211'}],
    #             serialize_methods => [ sub { Data::MessagePack->pack(+shift)},  sub {Data::MessagePack->unpack(+shift)} ],
    #         }),
    # # );
    # ),
#     state => Plack::Session::State::Cookie->new(
#         session_key => 'sid',
# #            httponly => 1,
#     );
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
