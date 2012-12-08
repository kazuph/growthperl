use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'PerlPad',
    AUTHOR        => 'Some Person <person@example.com>',
    VERSION_FROM  => 'lib/PerlPad.pm',
    PREREQ_PM     => {
        'Amon2'                           => '3.32',
        'Starman'                         => '0.3005',
        'Text::Xslate'                    => '1.5006',
        'Text::Xslate'                    => '1.4001',
        'Text::Xslate::Bridge::TT2Like'   => '0.00008',
        'Test::More'                      => '0.98',
        'Amon2::DBI'                      => '0.06',
        'DBD::SQLite'                     => '1.33',
        'HTML::FillInForm::Lite'          => '1.09',
        'JSON'                            => '2.50',
        'Plack::Middleware::ReverseProxy' => '0.09',
        'Plack::Middleware::Session'      => '0.15',
        'String::CamelCase'               => '0.02',
        'Plack::Session'                  => '0.14',
        'Test::WWW::Mechanize::PSGI'      => '0.35',
        'Time::Piece'                     => '1.20',
        'JSON'                            => '2.50',
        'Data::UUID'                      => '1.218',
        'Data::Dump'                      => '1.21',
        'IO::Scalar'                      => '2.110',
        'Time::Out'                       => '0.11',
        'Module::Find'                    => '0.11',
        'Diff::LibXDiff'                  => '0.05',
    },
    MIN_PERL_VERSION => '5.008001',
    (-d 'xt' and $ENV{AUTOMATED_TESTING} || $ENV{RELEASE_TESTING}) ? (
        test => {
            TESTS => 't/*.t xt/*.t',
        },
    ) : (),
);
