#!perl
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: mkdirs.pm

=head1

I<REVISION: 1>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: 01 Feb 2001>

=head1 PURPOSE:

Takes a path, and makes all of the dirs implicit in that path.

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

sub mkdirs {
  my ($param) = paramCheck([PATH => 'U'],@_);
  my ($wholedir) = $param->{PATH} =~ m{^(.*?)/[^/]+$};
  my $stepdir;

  while ($wholedir !~ /^\s*$/) {
    $wholedir =~ s{^(/?[^/]*/?)}{};
    $stepdir .= $1;
    mkdir $stepdir,0775 unless (-e $stepdir);
  }
}


1;
