package GrowthPerl::Web::Dispatcher;
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
use Data::Dumper;
{
    package Data::Dumper;
    sub qquote { return shift; }
}
$Data::Dumper::Useperl = 1;

any '/' => sub {
    my ($c) = @_;
    infof "REMOTE_USER %s", $c->request->env->{REMOTE_USER};

    my $entries = $c->dbh->selectall_arrayref(q{SELECT * FROM entry order by id desc;}, {Slice=>{}});

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
            entries   => $entries,
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
            $stdout =~ s/GrowthPerl::Web::Dispatcher:://g;

            $c->dbh->insert(
                entry => {
                    body      => $body,
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
        # if ($c->req->param('problem_id') == -1) {
            $c->redirect('/');
        # } else {
        #     $c->redirect("/problem/". scalar $c->req->param('problem_id') + 1);
        # }
    } else {
        $c->redirect('/');
    }
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
        my $stderr;
        my $start;
        my $end;
        {
            my $out = new IO::Scalar(\$stdout);
            my $err = new IO::Scalar(\$stderr);
            local *STDOUT = $out;
            local *STDERR = $err;
            $start = [gettimeofday];
            eval(
                $body
            );
            $end = [gettimeofday];
            if($@){$stdout = $@}
        }
        $stdout = $stderr.$stdout if $stderr;
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
