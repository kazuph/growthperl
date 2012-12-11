package PerlPad::Web::Dispatcher;
use strict;
use warnings;
use utf8;
use Amon2::Web::Dispatcher::Lite;
use Data::Dump qw/dump/;
use Time::Piece;
use Time::HiRes qw/time gettimeofday tv_interval/;
use IO::Scalar;
use Time::Out qw/timeout/;
use Diff::LibXDiff;
use Log::Minimal;

any '/' => sub {
    my ($c) = @_;

    my $entries = $c->dbh->selectall_arrayref(q{SELECT * FROM entry where user_name = ? and problem_id = -1 order by id desc;}, {Slice=>{}}, $c->request->env->{REMOTE_USER});

    for ( my $i = 0 ; $i < @$entries ; $i++ ) {
        my $t = localtime($$entries[$i]->{ctime});
        $$entries[$i]->{datetime} = $t->date." ".$t->time;
        if ( $i < @$entries - 1 ) {
            # create diff html
            my $diff_html = &diff_html( $$entries[$i]->{body}, $$entries[$i + 1]->{body} );
            $$entries[$i]->{diff_html} = $diff_html;
        }
    }

    $c->render('index.tt', {
            page_title => "SANDBOX",
            user_name => $c->req->env->{REMOTE_USER},
            entries   => $entries,
            problems  => $c->config->{PROBLEMS},
            problem_id => -1, 
        });
};

any '/problem/{id}' => sub {
    my ($c, $args) = @_;
    infof "ENV %s", $c->request->env;
    infof "REMOTE_USER %s", $c->request->env->{REMOTE_USER};

    my $entries = $c->dbh->selectall_arrayref(q{SELECT * FROM entry where user_name = ? and problem_id = ? order by id desc;}, {Slice=>{}}, $c->request->env->{REMOTE_USER}, $args->{id} -1 );

    # for my $entry (@$entries) {
    #     my $t = localtime($entry->{ctime});
    #     $entry->{datetime} = $t->date." ".$t->time;
    # }
    for ( my $i = 0 ; $i < @$entries ; $i++ ) {
        my $t = localtime($$entries[$i]->{ctime});
        $$entries[$i]->{datetime} = $t->date." ".$t->time;
        if ( $i < @$entries - 1 ) {
            # create diff html
            my $diff_html = &diff_html( $$entries[$i]->{body}, $$entries[$i + 1]->{body} );
            $$entries[$i]->{diff_html} = $diff_html;
        }
    }

    $c->render('index.tt', {
            page_title => "",
            user_name  => $c->req->env->{REMOTE_USER},
            entries    => $entries,
            problems   => $c->config->{PROBLEMS},
            problem_id => $args->{id} - 1,
        });
};

post '/post' => sub {
    my ($c) = @_;

    if (my $body = $c->req->param('body')) {

        my $stdout;
        my $run_time;
        my $id;
        eval{
            ($stdout, $run_time) = &eval_body($body);
            $stdout =~ s/\(eval \d+?\) //g;

            $c->dbh->insert(
                entry => {
                    body      => $body,
                    user_name => $c->request->env->{REMOTE_USER} // "NOT LOGIN USER",
                    problem_id => $c->req->param('problem_id') // -1,
                    result    => $stdout // "No Value",
                    run_time  => $run_time,
                    ctime     => time(),
                }
            );
            $id = $c->dbh->last_insert_id(undef,  undef,  undef,  undef);
        };
        if ($@) {
            critf "ERROR: $@n";
            critff "ERROR: $@n";
        }
        # $c->redirect("/entry/$id");
        if ($c->req->param('problem_id') == -1) {
            $c->redirect('/');
        } else {
            $c->redirect("/problem/". scalar $c->req->param('problem_id') + 1);
        }
    } else {
        $c->redirect('/');
    }
};

any '/users' => sub {
    my ($c) = @_;

    infof "REMOTE_USER %s", dump($c->request->env->{REMOTE_USER});
    return $c->redirect("/") unless ($c->request->env->{REMOTE_USER} eq "admin");

    my $users = $c->dbh->selectall_arrayref(q{SELECT distinct user_name FROM entry }, {Slice=>{}});

    $c->render('users.tt', {
            users => $users,
            user_name => $c->request->env->{REMOTE_USER} // "NOT LOGIN USER",
        });
};

any '/user/{user_name}' => sub {
    my ($c, $args) = @_;

    infof "REMOTE_USER %s", dump($c->request->env->{REMOTE_USER});

    my $problems = $c->dbh->selectall_arrayref(q{SELECT distinct problem_id FROM entry where user_name = ? order by problem_id;}, {Slice=>{}}, $args->{user_name});

    debugf "####%s", $problems;

    for my $problem (@$problems) {
        if ($problem->{problem_id} == -1) {
            $problem->{title} = "SANDBOX";
        } else {
            $problem->{title} = $c->config->{PROBLEMS}[$problem->{problem_id}]->{title};
        }
    }

    $c->render('user.tt', {
            problems     => $problems,
            user_name    => $args->{user_name},
        });
};

any '/user/{user_name}/problem/{problem_id}' => sub {
    my ($c, $args) = @_;

    infof "REMOTE_USER %s", dump($c->request->env->{REMOTE_USER});

    my $entries = $c->dbh->selectall_arrayref(q{SELECT * FROM entry where user_name = ? and problem_id = ? order by id desc;}, {Slice=>{}}, $args->{user_name}, $args->{problem_id});

    # for my $entry (@$entries) {
    #     my $t = localtime($entry->{ctime});
    #     $entry->{datetime} = $t->date." ".$t->time;
    # }
    for ( my $i = 0 ; $i < @$entries ; $i++ ) {
        my $t = localtime($$entries[$i]->{ctime});
        $$entries[$i]->{datetime} = $t->date." ".$t->time;
        if ( $i < @$entries - 1 ) {
            # create diff html
            my $diff_html = &diff_html( $$entries[$i]->{body}, $$entries[$i + 1]->{body} );
            $$entries[$i]->{diff_html} = $diff_html;
        }
    }

    $c->render('user_problem.tt', {
            entries     => $entries,
            user_name    => $args->{user_name},
        });
};

any '/problems' => sub {
    my ($c) = @_;

    infof "PROBLEMS %s", $c->config->{PROBLEMS};
    my $problems = $c->config->{PROBLEMS};

    $c->render('problems.tt', {
            problems     => $problems,
        });
};

sub eval_body {
    my ($stdout, $start, $end) = timeout 5, @_ => sub {

        my $body = shift;
        # escape
        $body =~ s/`/'/g;
        $body =~ s/system//g;
        $body =~ s/eval//g;

        # run code
        my $stdout;
        my $start;
        my $end;
        {
            my $fh = new IO::Scalar(\$stdout);
            local *STDOUT = $fh;
            eval(
                '$start = [gettimeofday];'
                .$body
                .'$end = [gettimeofday];'
            );
            if($@){$stdout = $@}
        }
        return ($stdout, $start, $end);
    };

    # Time Out.
    return ("No Result.", "Time Out.") if (ref $stdout eq "CODE");
    # Only Error Code.
    return ($stdout, "NaN") unless ($end);
    # Success Eval.
    return ($stdout, sprintf("%.6f", tv_interval($start,  $end)));
}

sub diff_html {
    my ($new, $old) = @_;
    my $diff_html;
    if ($old) {
        $diff_html = Diff::LibXDiff->diff( $old, $new );
        # add color like a git
        $diff_html =~ s/^(-.*?)(?:\r)?$/<span style="color:#f00;">$1<\/span>\r/mg;
        $diff_html =~ s/^(\+.*?)(?:\r)?$/<span style="color:#099;">$1<\/span>\r/mg;
        # delete "\ No newline at end of file"
        $diff_html =~ s/\\ No newline at end of file\n//g;
    }
    return $diff_html // "";
}

1;
