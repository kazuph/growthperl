use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'NoPaste',
    AUTHOR        => 'Some Person <person@example.com>',
    VERSION_FROM  => 'lib/NoPaste.pm',
    PREREQ_PM     => {
        'Amon2'                           => '3.20',
        'Text::Xslate'                    => '1.4001',
        'Text::Xslate::Bridge::TT2Like'   => '0.00008',
        'Test::More'                      => '0.98',
        'HTML::FillInForm::Lite'          => '1.09',
        'String::CamelCase'               => '0.02',
        'DBD::SQLite'                     => '1.33',
        'Log::Minimal'                    => '0.06',
        'Plack::Session'                  => '0.14',
        'Plack::Middleware::ReverseProxy' => '0.09',
        'Amon2::DBI'                      => '0.06',
        'Time::Piece'                     => '1.20',
        'Test::WWW::Mechanize::PSGI'      => '0',
        'JSON'                            => '2.50',
        'Plack::Middleware::Session'      => '0',
        'Data::UUID'                      => 0,
        'Data::Dump'                      => 0,
        'Time::Piece'                     => 0,
        'IO::Scalar'                      => 0,
        'Time::Out'                       => 0,
        'Module::Find'                    => 0,
        'Diff::LibXDiff'                  => 0,
    },
    MIN_PERL_VERSION => '5.008001',
    (-d 'xt' and $ENV{AUTOMATED_TESTING} || $ENV{RELEASE_TESTING}) ? (
        test => {
            TESTS => 't/*.t xt/*.t',
        },
    ) : (),
);
