+{
    'DBI' => [
        'dbi:SQLite:dbname=deployment.db',
        '',
        '',
        +{
            sqlite_unicode => 1,
        }
    ],
    'Text::Xslate' => +{
    },
    'Log::Dispatch' => {
        outputs => [
            ['Screen::Color', 
                min_level => 'debug',
                name      => 'debug',
                stderr    => 1,
                color     => {
                    debug => {
                        text => 'green',
                    }
                }
            ],
        ],
    },
};
