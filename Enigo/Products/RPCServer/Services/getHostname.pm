#!perl
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: getHostname.pm

Z<>

I<REVISION: $Revision: 1.1.1.1 $>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: $Date: 2001/12/17 02:28:37 $>

=head1 PURPOSE:

Returns the hostname, based on the output of /bin/hostname.

=head1 EXAMPLE:


=head1 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

use strict;

sub getHostname {
  open(HOSTNAME,"/bin/hostname|");
  my $hostname = <HOSTNAME>;
  chomp($hostname);
  close(HOSTNAME);

  $hostname =~ s/^\s*//;
  $hostname =~ s/\s*$//;
  return $hostname;
}


1;
