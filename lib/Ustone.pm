package Ustone;
use Dancer2;

use feature ':5.10';
our $VERSION = '0.1';
use Ustone::DB;
use Ustone::Dashboard;

sub db {
    state $db = Ustone::DB->new( 
        db_path => config->{'application'}->{'db_path'} 
    );
}

hook 'before_template' => sub {
    my $tokens = shift;
    $tokens->{platform_name} = config->{'application'}->{'platform_name'};
};

get '/' => sub { redirect '/uptime' };

get '/uptime' => sub {
    my $uptime = db->uptime;
    my $last = db->fetch_last_issue;
    my $message;
    my $color;

    if ($uptime < 5) {
        $color = '#bf0d0d';
    }
    elsif ($uptime < 10 ) {
        $color = '#ef8008';
    }
    elsif ($uptime < 20 ) {
        $color = '#1d499b';
    }
    else {
        $color = '#2b6829';
    }

    if ($uptime == 0) {
        $message = "Something is wrong";
    }
    elsif ($uptime == 1) {
        $message = "No worries since yesterday...";
    }
    elsif ($uptime < 30) {
        $message = "days without an issue";
    }
    else {
        $message = "Wow, so long!!";
    }

    template 'uptime',
      {
        uptime  => $uptime,
        message => $message,
        color   => $color,
        issue   => $last,
      };
};

post '/new' => sub {
    db->create(
        description => param('description'), 
        root_cause => param('root_cause'),
    );
    redirect '/';
};

get '/archives' => sub {
    my $archives = db->fetch_last_top(30, 0);
    template 'archives', { issues => $archives };
};

true;
