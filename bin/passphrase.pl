#!/usr/bin/env perl 
#PODNAME: passphrase

use strict;
use warnings;
use Digest::SHA1 'sha1_hex';

print "Enter passphrase: ";
my $clear = <STDIN>;
chomp($clear);
my $hex = sha1_hex($clear);

print "Add this to your config:
application:
  passphrase: \"$hex\"
";

