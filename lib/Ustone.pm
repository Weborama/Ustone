package Ustone;
use Dancer2;

our $VERSION = '0.1';

get '/' => sub {
    template 'index';
};

post '/new' => sub {
    
};

true;
