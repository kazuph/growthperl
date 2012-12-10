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
    infof "ENV %s", $c->request->env;
    infof "REMOTE_USER %s", dump($c->request->env->{REMOTE_USER});

    my $entries = $c->dbh->selectall_arrayref(q{SELECT * FROM entry where user_name = ? order by id desc;}, {Slice=>{}}, $c->request->env->{REMOTE_USER});

    for my $entry (@$entries) {
        my $t = localtime($entry->{ctime});
        $entry->{datetime} = $t->date." ".$t->time;
    }

    $c->render('index.tt', {
            user_name => $c->req->env->{REMOTE_USER},
            entries     => $entries,
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
        $c->redirect("/entry/$id");
    } else {
        $c->redirect('/');
    }
};

get '/entry/{id}' => sub {
    my ($c, $args) = @_;

    my $new = $c->dbh->selectrow_hashref(q{SELECT * FROM entry WHERE id=?}, {}, $args->{id});
    my $old = $c->dbh->selectrow_hashref(q{SELECT * FROM entry WHERE id=?}, {}, $new->{id} - 1);

    # create diff html
    my $diff_html;
    if ($old) {
        $diff_html = Diff::LibXDiff->diff( $old->{body}, $new->{body} );
        # add color like a git
        $diff_html =~ s/^(-.*?)(?:\r)?$/<span style="color:#f00;">$1<\/span>\r/mg;
        $diff_html =~ s/^(\+.*?)(?:\r)?$/<span style="color:#099;">$1<\/span>\r/mg;
        # delete "\ No newline at end of file"
        $diff_html =~ s/\\ No newline at end of file\n//g;
    }

    return $c->render('show.tt', {new => $new, old => $old, diff => $diff_html});
};

any '/users' => sub {
    my ($c) = @_;

    infof "REMOTE_USER %s", dump($c->request->env->{REMOTE_USER});
    $c->redirect("/") unless ($c->request->env->{REMOTE_USER} eq "admin");

    my $users = $c->dbh->selectall_arrayref(q{SELECT distinct user_name FROM entry }, {Slice=>{}});

    $c->render('users.tt', {
            users     => $users,
        });
};

any '/user/{user_name}' => sub {
    my ($c, $args) = @_;

    infof "REMOTE_USER %s", dump($c->request->env->{REMOTE_USER});

    my $entries = $c->dbh->selectall_arrayref(q{SELECT * FROM entry where user_name = ? order by id desc;}, {Slice=>{}}, $args->{user_name});

    for my $entry (@$entries) {
        my $t = localtime($entry->{ctime});
        $entry->{datetime} = $t->date." ".$t->time;
    }

    $c->render('user.tt', {
            entries     => $entries,
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

1;
