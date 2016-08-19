#!perl
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: dbInit.pm

=head1

I<REVISION: 1>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: 19 Mar 2001

=head1 PURPOSE:

Takes a db connect string and attempts to connect to a database.
It will return the database handle if successful, or undef if
unsuccessful.

=head1 EXAMPLE:

=head1 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

use strict;
use DBI;
use Data::Dumper;
use Enigo::Common::ParamCheck qw(paramCheck);

sub dbInit {
  my ($param) = paramCheck([DSN => 'UO',
                            VENDOR => 'AO',
                            DB => 'ANO',
                            USER => 'ANO',
                            AUTH => 'UO',
                            ATTRIB => 'HRO'],@_);

  my $commit_interval;
  ($param->{VENDOR},$param->{USER},$param->{AUTH},$param->{DB},$commit_interval) =
    $param->{DSN} =~ m{^(\w+):([^/]+)/([^\@]*)\@(\w+)(?::(\d+))?}i
      if $param->{DSN};

  if (defined $commit_interval and $commit_interval and !$param->{ATTRIB}) {
    $param->{ATTRIB} = {AutoCommit => 0,
            RaiseError => 1,
            PrintError => 0};
  } elsif (defined $commit_interval and !$commit_interval and !$param->{ATTRIB}) {
    $param->{ATTRIB} = {AutoCommit => 1,
            RaiseError => 1,
            PrintError => 0};
  } elsif (!$param->{ATTRIB}) {
    $param->{ATTRIB} = {AutoCommit => 1,
            RaiseError => 1,
            PrintError => 0};
  }

  my $dbh;
  eval {
    $dbh = DBI->connect("dbi:$param->{VENDOR}:$param->{DB}",
            $param->{USER},
            $param->{AUTH},
            $param->{ATTRIB});
  };
      return wantarray ? ($dbh,$commit_interval) : $dbh;
}


1;
