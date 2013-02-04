#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Cinnamon::DSL;

# command
# $ cinnamon production deploy:update
# $ cinnamon production server:restart

my $application = 'PerlPad';
my $server = '';
my $user = '';

set application => $application;
set repository  => "https://github.com/kazuph/$application.git";

role localhost => [ 'localhost' ], {
    deploy_to   => ".",
    branch      => 'master',
};

role development => [ $server ], {
    deploy_to   => "/home/$user/$application",
    branch      => 'master',
};

role production => [ $server ], {
    deploy_to   => "/home/$user/$application",
    branch      => 'master',
};

task deploy  => {
    setup => sub {
        my ($host, @args) = @_;
        my $repository = get('repository');
        my $deploy_to  = get('deploy_to');
        my $branch   = 'origin/' . get('branch');
        remote {
            run "git clone $repository $deploy_to && git checkout -q $branch";
        } $host;
    },
    update => sub {
        my ($host, @args) = @_;
        my $deploy_to = get('deploy_to');
        my $branch   = 'origin/' . get('branch');
        remote {
            run "cd $deploy_to && git fetch origin && git checkout -q $branch && git submodule update --init";
        } $host;
    },
};

task server => {
    start => sub {
        my ($host, @args) = @_;
        my $application_lc = lc $application;
        remote {
            run "supervisorctl start $application_lc";
        } $host.'-root';
    },
    stop => sub {
        my ($host, @args) = @_;
        my $application_lc = lc $application;
        remote {
            run "supervisorctl stop $application_lc";
        } $host.'-root';
    },
    restart => sub {
        my ($host, @args) = @_;
        my $application_lc = lc $application;
        remote {
            # run "kill -HUP `cat /tmp/myapp.pid`";
            run "supervisorctl restart $application_lc";
        } $host.'-root';
    },
    status => sub {
        my ($host, @args) = @_;
        remote {
            run "supervisorctl status";
        } $host.'-root';
    },
};

task carton => {
    install => sub {
        my ($host, @args) = @_;
        my $deploy_to = get('deploy_to');
        remote {
            run ". ~/perl5/perlbrew/etc/bashrc && cd $deploy_to && carton install";
        } $host;
    },
};

task localhost => {
    cpaninstall => sub {
        my ($host, @args) = @_;
        run "./bin/cpaninstall.sh";
    },
    start => sub {
        my ($host, @args) = @_;
        run "./bin/run_dev.sh";
    },
};
