package Ustone::DB;
#ABSTRACT: model to store all issues

=head1 DESCRIPTION

This is the dumbiest ORM we could imagine: a stupid array of hashref containing
issues.

It's stored in a storable file and retreived from there.

=cut

use Moo;
use DateTime;
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

sub fetch_last_issue {
    my ($self) = @_;

    my $sql = "select * from issues order by created_at desc limit 1";
    my $sth = $self->_dbh->prepare($sql);
    $sth->execute;
    return $sth->fetchrow_hashref;
}

sub fetch_last_top {
    my ($self, $number) = @_;
    $number //= 10;

    my $sql = "select * from issues order by created_at desc limit 1,$number";
    my $sth = $self->_dbh->prepare($sql);
    $sth->execute;
    my $results = [];
    while (my $r = $sth->fetchrow_hashref) {
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
