# db.t

use strict;
use warnings;
use Test::More;

use Ustone::DB;
use File::Spec;
use File::Basename 'dirname';

my $db_file = File::Spec->catfile(dirname(__FILE__), 'test.db');

my $db = Ustone::DB->new( db_path => $db_file );

is $db->size, 0, "db is empy";
is_deeply [], $db->fetch_last, "nothing inside the db";

$db->create(
    description => "Unable to serve impression when collecting data",
    root_cause => "mistake during a hotfix deployment",
);

is $db->size, 1, "an issue is added to the db";

$db->purge;
is $db->size, 0, "db has been purge";

done_testing;

