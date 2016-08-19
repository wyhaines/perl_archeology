#!perl
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: $RCSfile: purgeSeen.pm,v $

=head1

I<REVISION: $Revision: 1.1.1.1 $>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: $Date: 2001/12/17 02:28:37 $>

=head1 PURPOSE:

Takes a list of files and/or a time value and purges from the seen
database all entries that either have an lsdate older than the time
value or which are not among the list of files.

=head1 EXAMPLE:

=head1 TODO:

Currently the code only actually takes a time value.  It's
functionality should be enhanced to match the above description.

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

use strict;
use Enigo::Common::ParamCheck qw(paramCheck);
use Data::Dumper;

sub purgeSeen {
  my ($param) = paramCheck([TIME => ['I',-1]],@_);

  my $sql = $Enigo::Products::RPCServer::SQL;

  my @paths = $sql->row_list('select path,lsdate from seen');

  #If the file doesn't exist anymore, or it's older than our time
  #threshold, remove it from the seen database.
  foreach my $path (@paths) {
    if (!(-e $path->[0]) or
    ($param->{TIME} > -1 and
     $path->[1] < $param->{TIME})) {
      deleteSeen({PATH => $path->[0]});
    }
  }
}

1;
