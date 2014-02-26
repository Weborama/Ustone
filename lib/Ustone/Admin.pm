package Ustone::Dashboard;

use feature ':5.10';
use Dancer2;
use Dancer2::Plugin::Ajax;
use Dancer2::Plugin::Deferred;
use Digest::SHA1 'sha1_hex';
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

any ['get', 'post'], '/auth' => sub {
    my $message;
    if (request->is_post) {
        my $passphrase    = param('passphrase');
        my $expected_hash = config->{'application'}->{'passphrase'};
        if (sha1_hex($passphrase) eq $expected_hash) {
            session admin => 1;
            redirect '/admin';
        }
        else {
            deferred error => "The passphrase is not valid, please try again.";
        }
    }
    template 'auth.tt';
};

sub request_administrator {
    if (! session('admin')) {
        deferred warning => "Session invalid or expired, please authenticate yourself";
        redirect '/auth';
    }
}

get '/admin' => sub {
    request_administrator();
    template 'dashboard',
      {
        uptime  => db->uptime,
        size    => db->size,
        top     => db->fetch_last_top(3),
        current => db->fetch_last_issue,
      };
};

post '/new' => sub {
    request_administrator();

    db->create(
        description => param('description'), 
        root_cause => param('root_cause'),
    );

    deferred success => "Issue saved correctly, uptime reset is done.";
    redirect '/';
};

post '/update' => sub {
    request_administrator();

    db->update(
        id          => param('id'),
        description => param('description'), 
        root_cause => param('root_cause'),
    );
    redirect '/archives';
};

ajax '/delete/:id' => sub {
    request_administrator();

    my $id = param('id');
    content_type 'application/json';
    to_json{ status => db->delete($id) };
};

1;
