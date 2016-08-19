#!perl
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: deleteSeen.pm

=head1

I<REVISION: 1>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: 01 Feb 2001>

=head1 PURPOSE:

Deletes a given file from the seen database.

=head1 EXAMPLE:

=head1 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

use strict;
use Enigo::Common::ParamCheck qw(paramCheck);

sub deleteSeen {
  my ($param) = paramCheck([PATH => 'U'],@_);


  my $sql = $Enigo::Products::RPCServer::SQL;

  $sql->delete(<<ESQL);
delete from seen where
path = '$param->{PATH}'
ESQL

  return undef;
}


1;
