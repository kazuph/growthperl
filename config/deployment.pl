use File::Spec;
use File::Basename qw(dirname);
use YAML::XS;
use Log::Minimal;
use Data::Dump qw/dump/;
use IO::File;

my $basedir = File::Spec->rel2abs(File::Spec->catdir(dirname(__FILE__), '..'));
my $dbpath;
if ( -d '/home/dotcloud/') {
    $dbpath = "/home/dotcloud/db/deployment.db";
} else {
    $dbpath = File::Spec->catfile($basedir, 'db', 'deployment.db');
}

# read problem.yml
my $problems;
if ( -d "$basedir/config/problems/") {
    $problems = YAML::XS::LoadFile("$basedir/config/problems/problem.yml");
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
