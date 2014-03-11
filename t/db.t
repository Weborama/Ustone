# db.t

use strict;
use warnings;
use Test::More;
use Test::MockTime ':all';

use Ustone::DB;
use File::Spec;
use File::Basename 'dirname';

my $db_file = File::Spec->catfile( dirname(__FILE__), 'test.db' );
my $db = Ustone::DB->new( db_path => $db_file );
$db->purge;

subtest "basic DB manipulation" => sub {
    is $db->size, 0, "db is empy";
    is_deeply [], $db->fetch_last_top, "nothing inside the db";

    $db->create(
        description => "issue 1",
        root_cause  => "mistake during a hotfix deployment",
    );

    is $db->size, 1, "an issue is added to the db";

    $db->create(
        description => "issue $_",
        root_cause  => "root cause for $_",
    ) for ( 2 .. 5 );

    my $issue = $db->fetch_last_issue;
    is $issue->{description}, "issue 1", "last issue is issue 1";

    my $top = $db->fetch_last_top;
    is @{$top}, 4, "4 issues in the top";
    is $top->[0]->{description}, "issue 2", "first issue of top is 2";

    $db->purge;
};

subtest "uptime works as expected" => sub {
    my $today         = 1393253222;
    my $five_days_ago = $today - 3600 * 24 * 5;
    set_absolute_time($five_days_ago);

    $db->create(
        description => "issue 5 days ago",
        root_cause  => "This was an issue caused by Foo!",
    );

    is $db->fetch_last_issue->{uptime_since}, undef,
      "Only one issue in DB, 'uptime_since' is undef";
    set_absolute_time($today);

    $db->create(
        description => "issue today",
        root_cause  => "This was an issue caused by Foo!",
    );

    is $db->fetch_last_issue->{uptime_since}, undef,
      "Issue created 5 days later, 'uptime_since' is undefined for the newly created issue..";

    my $previous = $db->fetch_last_top(1, 1);
    is $previous->[0]->{description}, "issue 5 days ago", "5 days ago";
    is $previous->[0]->{uptime_since}, 5, "... but prevous issue has an uptime_since of 5";

    $db->purge;
};

is $db->size, 0, "The db has been purge, test can eand cleanly.";
done_testing;
