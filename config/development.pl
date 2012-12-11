use File::Spec;
use File::Basename qw(dirname);
use YAML::XS;
# use Log::Minimal;
# use Data::Dump qw/dump/;
use IO::File;

my $basedir = File::Spec->rel2abs(File::Spec->catdir(dirname(__FILE__), '..'));
my $dbpath;
if ( -d '/home/dotcloud/') {
    $dbpath = "/home/dotcloud/db/development.db";
} else {
    $dbpath = File::Spec->catfile($basedir, 'db', 'development.db');
}

# read problems.yml
my $problems;
if ( -d "$basedir/config/problems/") {
    $problems = YAML::XS::LoadFile("$basedir/config/problems/problems.yml");
}
+{
    'DBI' => [
        "dbi:SQLite:dbname=$dbpath",
        '',
        '',
        +{
            sqlite_unicode => 1,
        }, 
    ],
    'PROBLEMS' => $problems,
};
