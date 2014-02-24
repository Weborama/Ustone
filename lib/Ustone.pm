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

get '/' => sub {
    template 'index', { 
        uptime => db->uptime,
        top => db->fetch_last_top,
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
