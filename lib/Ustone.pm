package Ustone;
use Dancer2;

use feature ':5.10';
our $VERSION = '0.1';
use Ustone::DB;

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

    if ($uptime < 0) {
        $message = "We got an issue!";
    }
    elsif ($uptime < 2) {
        $message = "No worries since yesterday...";
    }
    elsif ($uptime < 44) {
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

get '/dashboard' => sub {
    template 'index', { 
        uptime => db->uptime,
        top => db->fetch_last_top(3),
        current => db->fetch_last_issue,
    };
};

get '/new' => sub { template 'new' };

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
