#!/usr/bin/perl -wc
#
######################################################################
##### Header
######################################################################

=pod

=head1 NAME

SQLite.pm - DBD driver for SQLite

=head1

I<REVISION: $Revision: 1.1.1.1 $>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: 27 Jun 2001>

=head1 SYNOPSIS

A DBD::SQLite driver for using SQLite databases via DBI.  This driver
is still in development, but currently encompasses enough
functionality to be at least nominally useful.  Find out more about
SQLite at:

http://www.hwaci.com/sw/sqlite/

=head1 DESCRIPTION

=head1 EXAMPLES:

  my $dbh = DBI->connect('dbi:SQLite:griswald;666');

  my $rv = $dbh->do(<<ESQL);
    create table tests (name char(20) primary key,result char(20))
  EQSL

  my $sth = $dbh->prepare("select * from tests");
  $sth->execute();

  $sth = $dbh->prepare("select * from tests where name = :1");
  $sth->execute($name);

=head1 TODO:

  There is a substantial subset of the DBI spec that is not yet
  implemented.

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

use Enigo::Common::Exception qw(:DB :general :Config);
require Enigo::Common::Exception::SQL;
require Enigo::Common::Exception::SQL::FailedSQLStatement;
use Data::Dumper;

use sqlite;

{ package DBD::SQLite;

  use DBI qw(:sql_types);
  use DynaLoader ();
  use Exporter ();

  @EXPORT = qw(); # Do NOT @EXPORT anything.
  $VERSION = "0.02";

  $err = 0;
  $errstr = '';
  $drh = undef; # holds driver handle once initialised

  sub driver {
    return $drh if $drh;

    my ($class,
    $attr) = @_;

    $class .= "::dr";
    $drh = DBI::_new_drh
      ($class,
       {Name => 'SQLite',
    Version => $VERSION,
    Err => \$DBD::SQLite::err,
    Errstr => \$DBD::SQLite::errstr,
    Attribution => join('',
                "DBD::SQLite $VERSION using SQLite ",
                sqlite::version(),
                ' by Kirk Haines.')});
    return $drh;
  }

  sub default_user {
    return ('','');
  }
}

{ package DBD::SQLite::dr;
  $imp_data_size = 0;
  use strict;

  sub date_sources {
    return undef;
  }

  sub connect {
    my ($drh,
    $dbname,
    $user,
    $auth,
    $attr) = @_;

    my $mode;

    if (index($dbname,';') >= 0) {
      ($dbname,$mode) = split(/;/,$dbname,2);
    }

    $mode = $mode ? $mode : 666;

    my $sqlobj = sqlite::open_db($dbname,$mode);
    unless (ref $sqlobj) {
      $drh->{Err} = 1;
      $drh->{Errstr} = $sqlobj;
      return undef;
    }

    my $dbh = DBI::_new_dbh
      ($drh,
       {Name => $dbname,
    Mode => $mode,
    sqlobj => $sqlobj});

    $dbh->STORE(Active => 1);
    return $dbh;
  }

  sub data_sources {
    return undef;
  }

  sub disconnect_all {
    return undef;
  }

  sub DESTROY {undef};
}


{ package DBD::SQLite::db;
  $imp_data_size = 0;
  use strict;

  sub prepare {
    my ($dbh,
    $statement) = @_;

    my $param_index = 0;
    foreach my $param_marker ($statement =~ m{(?:\s|[^\w])(\?|:\w)\s?}g) {
      if ($param_marker eq '?') {
    $param_index++;
    $statement =~ s{(\s|[^\w])\?\s?}{$1:$param_index};
      }
      else {
    my $num = substr($param_marker,1);
    $param_index = $num;
      }
    }

    my $sth = DBI::_new_sth
      ($dbh,
       {Statement => $statement,
        DBH => $dbh});

    return $sth;
  }

  sub FETCH {
    my ($dbh, $attrib) = @_;
    # In reality this would interrogate the database engine to
    # either return dynamic values that cannot be precomputed
    # or fetch and cache attribute values too expensive to prefetch.
    return 1 if $attrib eq 'AutoCommit';
    # else pass up to DBI to handle
    return $dbh->DBD::_::db::FETCH($attrib);
  }

  sub STORE {
    my ($dbh, $attrib, $value) = @_;
    # would normally validate and only store known attributes
    # else pass up to DBI to handle
    if ($attrib eq 'AutoCommit') {
      return 1 if $value; # is already set
      croak("Can't disable AutoCommit");
    }
    return $dbh->DBD::_::db::STORE($attrib, $value);
  }

  sub DESTROY {
    my $self = shift;

    $self->disconnect() if ($self->{sqlobj});;
    delete $self->{sqlobj};
  }

  sub disconnect {
    my $self = shift;

    my $active = $self->FETCH('Active');
    return undef unless $active;
    $self->STORE(Active => 0);
    my $foo = sqlite::close_db($self->{sqlobj});
    return $foo
  }
}


{ package DBD::SQLite::ResultSet;

  sub new {
    my $class = shift;
    my $self = {FIELDS => [],
        FIELD_POS => {},
        ROWS => [],
        POS => 0};

    bless ($self,$class);
  }

  sub reset {
    my $self = shift;
    $self->set_pos(0);
  }

  sub set_pos {
    my ($self,
    $position) = @_;
    $self->{POS} = $position;
    return $position;
  }

  sub get_pos {
    my $self = shift;

    return $self->{POS};
  }

  sub clear {
    my $self = shift;

    $self->{FIELDS} = [];
    $self->{FIELD_POS} = {};
    $self->{ROWS} = [];
    $self->{POS} = 0;

    return '0E0';
  }

  sub insert {
    my ($self,
    $row) = @_;

    unless($#{$self->{FIELDS}} >= 0) {
      $self->{FIELDS} = $row->{FIELDS};
      $self->{FIELD_POS} = $row->{FIELD_POS};
    }

    push(@{$self->{ROWS}},$row->{VALUES});
    return $row;
  }

  sub head {
    my $self = shift;

    return $self->set_pos(0);
  }

  sub tail {
    my $self = shift;

    return $self->set_pos($#{$self->{ROWS}});
  }

  sub getnext {
    my $self = shift;

    if ($self->{POS} > $#{$self->{ROWS}}) {
      return undef;
    }

    return $self->{ROWS}->[$self->{POS}++];
  }

  sub getprev {
    my $self = shift;

    if ($self->{POS} < 0) {
      return undef;
    }

    return $self->{ROWS}->[$self->{POS}--];
  }

  sub get {
    my ($self,
    $position) = @_;

    if ($position < 0 or
    $position > $#{$self->{ROWS}}) {
      return undef;
    }

    return $self->{ROWS}->[$position];
  }
}


{ package DBD::SQLite::st;
  $imp_data_size = 0;
  use strict;

  sub _clear_resultset {
    my $self = shift;

    $self->{_RS}->clear();
  }

  sub _insert_resultset_row {
    my ($self,
    $argc,
    $argv,
    $column_names) = @_;

    my $field_pos = {};
    for (my $k = 0;$k <= $#{$argv};$k++) {
      $field_pos->{$column_names->[$k]} = $k;
    }

    $self->{_RS}->insert({FIELDS => $column_names,
              FIELD_POS => $field_pos,
              VALUES => $argv});

    return 0;
  }

  sub do {
    my ($self,
    $statement) = @_;

    unless ($self->{_RS}) {
      $self->{_RS} = DBD::SQLite::ResultSet->new();
    }

    $self->{_RS}->clear();

    my $rv = sqlite::exec_sql($self->{DBH}->{sqlobj},
                  $statement,
                  \&_insert_resultset_row,
                  $self);

    if ($rv->[0]) {
      my $sql_exception =
    Enigo::Common::Exception::SQL->new($rv->[1]);
      $sql_exception->attach
    (Enigo::Common::Exception::SQL::FailedSQLStatement->new($statement));
      throw $sql_exception;
    }

    my $rows = $self->rows();
    return ($rows == 0) ? '0E0' : $rows;
  }

  sub rows {
    my $self = shift;

    unless ($self->{_RS}) {
      $self->{_RS} = DBD::SQLite::ResultSet->new();
    }

    return scalar(@{$self->{_RS}->{ROWS}});
  }

  sub execute {
    sub quote_it {
      my $value = shift;
      $value =~ s{\'}{''}g;
      return "'$value'";
    }

    my $self = shift;
    my @params = @_;
    my $sql_statement = $self->{Statement};

    if (@params) {
      my $index = 1;
      while ($index <= scalar(@params)) {
    my $param_marker = ":$index";
    $sql_statement =~ s{^([^']*(?:'(?:[^']*|'')*'[^']*)*)$param_marker}{$1 . quote_it($params[$index - 1])}e;
    $index++;
      }
    }

    unless ($self->{_RS}) {
      $self->{_RS} = DBD::SQLite::ResultSet->new();
    }
    $self->{_RS}->clear();

    my $rv = sqlite::exec_sql($self->{DBH}->{sqlobj},
                  $sql_statement,
                  \&_insert_resultset_row,
                  $self);

    if ($rv->[0]) {
      my $sql_exception =
    Enigo::Common::Exception::SQL->new($rv->[1]);
      $sql_exception->attach
    (Enigo::Common::Exception::SQL::FailedSQLStatement->new($sql_statement));
      throw $sql_exception;
    }

    return $rv;
  }


  sub fetch {
    my $self = shift;

    my $row = $self->{_RS}->getnext();
    unless ($row) {
      $self->finish;     # no more data so finish
      return undef;
    }

    return $row;
  }
  *fetchrow_arrayref = \&fetch;

  sub fetchrow_array {
    my $self = shift;

    my $row = $self->fetch();

    return wantarray ? @{$row} : $row->[0];
  }

  sub fetchrow_hashref {
    my $self = shift;

    my $row = $self->fetch();

    my %hash;
    @hash{@{$self->{_RS}->{FIELDS}}} = (@{$row});
    return \%hash;
  }

  sub finish {
    my $self = shift;
    $self->{_RS}->clear();
    $self->SUPER::finish();
    return 1;
  }

  sub FETCH {
    my ($sth, $attrib) = @_;
    # would normally validate and only fetch known attributes
    # else pass up to DBI to handle
    return $sth->DBD::_::st::FETCH($attrib);
  }

  sub STORE {
    my ($sth, $attrib, $value) = @_;
    # would normally validate and only store known attributes
    # else pass up to DBI to handle
    return $sth->DBD::_::st::STORE($attrib, $value);
  }

  sub DESTROY {
    undef;
  }
}

=pod

=head1 NOTES

=head2 Changelog

$Log: SQLite.pm,v $
Revision 1.1.1.1  2001/12/17 02:28:37  khaines
Hierarchy of custom Perl modules

Revision 1.2  2001/08/14 22:01:18  khaines
Added a CVS based version and inserted the changelog to the end of the
file as POD.


=cut

1;
