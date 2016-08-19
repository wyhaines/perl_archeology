#!perl
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: packetSize.pm

Z<>

I<REVISION: $Revision: 1.1.1.1 $>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: $Date: 2001/12/17 02:28:37 $>

=head1 PURPOSE:

Returns the length, in bytes, of the data segments within the packet.

=head1 EXAMPLE:

  my $size = packetSize($packet);


=head1 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

use strict;

sub packetSize {
  my ($param) = paramCheck([PACKET => 'U'],@_);

  my $size;
  foreach my $file (keys %{$param->{PACKET}}) {
    $size += length $param->{PACKET}->{$file}->[0];
  }

  return $size;
}
