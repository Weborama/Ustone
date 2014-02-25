package Ustone::DB;
#ABSTRACT: model to store all issues

=head1 DESCRIPTION

This is the dumbiest ORM we could imagine: a stupid array of hashref containing
issues.

It's stored in a storable file and retreived from there.

=cut

use Moo;
use DateTime;
use DateTime::Duration::Fuzzy qw(time_ago);
use Carp 'croak';
use DBI;

=attr db_path

Where to store the database binary file.

Defaults is C<issues.db> in the local directory.

=cut

has db_path => (is => 'ro', default => sub { 'issues.db' });
has issues => ( is => 'lazy' );
has _dbh => (is => 'lazy' );

sub _build__dbh {
    my ($self) = @_;
    my $dbfile = $self->db_path;
    return DBI->connect("dbi:SQLite:dbname=$dbfile","","");
}

sub _build_issues {
    my ($self) = @_;
    my $sql = "select * from issues";
    my $sth = $self->_dbh->prepare($sql);
    $sth->execute;
    return $sth->fetchall_arrayref;
}

sub uptime {
    my ($self) = @_;
    my $last_date = DateTime->from_epoch(epoch => $self->fetch_last_issue->{created_at} );
    my $now = DateTime->now;
    int($now->subtract_datetime_absolute($last_date)->delta_seconds / (24*60*60));
}

sub fetch_last_issue {
    my ($self) = @_;

    my $sql = "select * from issues order by created_at desc limit 1";
    my $sth = $self->_dbh->prepare($sql);
    $sth->execute;
    my $r = $sth->fetchrow_hashref;
    $r->{date_ago} =
      time_ago( DateTime->from_epoch( epoch => $r->{created_at} ), DateTime->now );
    return $r;
}

sub fetch_last_top {
    my ($self, $number, $offset) = @_;
    $number //= 10;
    $offset //= 1;

    my $sql = "select * from issues order by created_at desc limit $offset,$number";
    my $sth = $self->_dbh->prepare($sql);
    $sth->execute;
    my $results = [];
    while ( my $r = $sth->fetchrow_hashref ) {
        my $dt = DateTime->from_epoch( epoch => $r->{created_at} );
        $r->{date_ago} = time_ago( $dt, DateTime->now );
        $r->{date} = $dt->ymd('-') . ' ' . $dt->hms(':');
        push @{$results}, $r;
    }
    return $results;
}

sub size { 
    my $self = shift;
    my $sql = "select count(*) from issues";
    my $sth = $self->_dbh->prepare($sql);
    $sth->execute;
    my $r = $sth->fetchrow_arrayref;
    return $r->[0];
}

sub purge {
    my ($self) = @_;
    $self->_dbh->do("delete from issues");
}

sub delete {
    my ($self, $id) = @_;
    my $sth = $self->_dbh->prepare("delete from issues where id = ?");
    $sth->execute($id);
}

sub update {
    my ($self, %attrs) = @_;

    my $id = $attrs{id};
    croak "Need an issue id" if ! defined $id;

    my $description = $attrs{description};
    croak "Need an issue description" if ! defined $description;

    my $root_cause = $attrs{root_cause};
    croak "Need a route cause" if ! defined $root_cause;

    my $sth = $self->_dbh->prepare("update issues set description = ?, root_cause = ? where id = ?");
    $sth->execute($description, $root_cause, $id);
}

sub create {
    my ($self, %attrs) = @_;

    my $description = $attrs{description};
    croak "Need an issue description" if ! defined $description;

    my $root_cause = $attrs{root_cause};
    croak "Need a route cause" if ! defined $root_cause;

    my $date = DateTime->now->epoch;

    my $sql = "insert into issues (description, root_cause, created_at) "
            . "values (?, ?, ?)";
    
    my $sth = $self->_dbh->prepare($sql);
    $sth->execute($description, $root_cause, $date);
}

1;
