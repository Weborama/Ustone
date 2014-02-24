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
is_deeply [], $db->fetch_last_top, "nothing inside the db";

$db->create(
    description => "issue 1",
    root_cause => "mistake during a hotfix deployment",
);

is $db->size, 1, "an issue is added to the db";


$db->create(
    description => "issue $_",
    root_cause => "root cause for $_",
) for (2 .. 5);

my $issue = $db->fetch_last_issue;
is $issue->{description}, "issue 1", "last issue is issue 1";

my $top = $db->fetch_last_top;
is @{ $top }, 4, "4 issues in the top";
is $top->[0]->{description}, "issue 2", "first issue of top is 2";

$db->purge;
is $db->size, 0, "db has been purge";

done_testing;

