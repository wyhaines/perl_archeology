#!/usr/bin/perl -wc
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: lib.pm

=head1

I<REVISION: $Revision: 1.1.1.1 $>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: $Date: 2001/12/17 02:28:37 $>

=head1 PURPOSE:

Modifies @INC to include the proper Enigo specific architecture
independent and dependent directories.  It works by looking at
the @INC settings and using them to deduce what the architecture
portion of the directory path should be, when combined with the
path(s) passed into it.

=head1 EXAMPLE:

  use Enigo::lib('/opt/enigo/lib/perl5');

=head1 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

package Enigo::lib;

use strict;

($Enigo::lib::VERSION) = ('$Revision: 1.1.1.1 $' =~ m{:\s+([\d\.]+)});;


sub import {
  my $package = shift;
  my @inc;

  foreach my $path (@INC) {
    next unless
      $path =~ m{(/\d+\.\d+(?:\.\d+)*/?.*|/site_perl/?.*)};
    push(@inc,$1);
  }

  foreach my $path (@_) {
    chop($path) if rindex($path,'/') == (length($path) - 1);
    foreach my $inc (@inc) {
      push(@INC,join('',$path,$inc));
    }
  }
}
1;
