package NoPaste::Web::Dispatcher;
use strict;
use warnings;
use Amon2::Web::Dispatcher::Lite;
use Data::UUID;
use Data::Dump qw/dump/;
use Time::Piece;
use Time::HiRes qw/time gettimeofday tv_interval/;
use IO::Scalar;
use Time::Out qw/timeout/;
use Diff::LibXDiff;

my $uuid = Data::UUID->new();

any '/' => sub {
    my ($c) = @_;
    my ($entries_cnt) = $c->dbh->selectrow_array(q{SELECT COUNT(*) FROM entry;});
    my $entries = $c->dbh->selectall_arrayref(q{SELECT * FROM entry order by id desc;}, {Slice=>{}});

    for my $entry (@$entries) {
        my $t = localtime($entry->{ctime});
        $entry->{datetime} = $t->date." ".$t->time;
    }

    $c->render('index.tt', {
        entries_cnt => $entries_cnt,
        entries     => $entries,
    });
};

post '/post' => sub {
    my ($c) = @_;

    if (my $body = $c->req->param('body')) {
        my $entry_id = $uuid->create_str();
        
        my ($stdout, $run_time) = &eval_body($body);

        $c->dbh->insert(
            entry => {
                entry_id => $entry_id,
                body     => $body,
                ctime    => time(),
                result   => $stdout // "No Value",
                run_time => $run_time,
            }
        );
        $c->redirect("/entry/$entry_id");
    } else {
        $c->redirect('/');
    }
};

get '/entry/{entry_id}' => sub {
    my ($c, $args) = @_;

    my $new = $c->dbh->selectrow_hashref(q{SELECT * FROM entry WHERE entry_id=?}, {}, $args->{entry_id});
    my $old = $c->dbh->selectrow_hashref(q{SELECT * FROM entry WHERE id=?}, {}, $new->{id} - 1);

    # create diff html
    my $diff_html;
    if ($old) {
        $diff_html = Diff::LibXDiff->diff( $old->{body}, $new->{body} );
    }


    return $c->render('show.tt', {new => $new, old => $old, diff => $diff_html});
};

sub eval_body {
    my ($stdout, $start, $end) = timeout 5, @_ => sub {

        my $body = shift;
        # エスケープ
        $body =~ s/`/'/g;
        $body =~ s/system//g;
        $body =~ s/eval//g;

        # 実行する
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