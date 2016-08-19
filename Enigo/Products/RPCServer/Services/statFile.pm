#!perl
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: statFile.pm

=head1

I<REVISION: $Revision: 1.1.1.1 $>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: $Date: 2001/12/17 02:28:37 $>

=head1 PURPOSE:

Pulls the seen stats and the stat() information on a file and
returns it.

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

sub statFile {
  my ($param) = paramCheck([PATH => 'U',
                ALLSTATS => ['U',0]],@_);

  my $sql = $Enigo::Products::RPCServer::SQL;

  my @seenparams =
    $sql->row(<<ESQL,$param->{PATH});
select confdate,
       confpos,
       trandate,
       tranpos,
       length,
       hash,
       status,
       retrycount from seen where
       path = ?
ESQL

  my @statparams;

  @statparams = $param->{ALLSTATS} ?
    stat($param->{PATH}) : (stat($param->{PATH}))[7..10];

  return (\@seenparams,\@statparams);
}


1;
