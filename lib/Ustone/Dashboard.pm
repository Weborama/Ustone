package Ustone::Dashboard;

use feature ':5.10';
use Dancer2;
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

hook 'before' => sub {
    return if request->path eq '/auth';
    redirect '/auth' if ! session('admin');
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
            $message = "bad passphrase";
        }
    }
    template 'auth.tt', { message => $message };
};

get '/admin' => sub {
    template 'dashboard',
      {
        uptime  => db->uptime,
        size    => db->size,
        top     => db->fetch_last_top(3),
        current => db->fetch_last_issue,
      };
};


1;
