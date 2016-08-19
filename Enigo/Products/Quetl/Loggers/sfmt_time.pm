#!perl
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: sfmt_time.pm

=head1

I<REVISION: 1>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: 01 Feb 2001>

=head1 PURPOSE:

Returns time/date in a standard format.

=head1 EXAMPLE:

=head1 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

use strict;
use POSIX qw(asctime);
use Enigo::Common::ParamCheck qw(paramCheck);

sub sfmt_time {
  my ($param) = paramCheck([TIME => 'NO'],@_);
  $param->{TIME} = time() unless defined $param->{TIME};

  my $time = POSIX::asctime(localtime($param->{TIME}));
  chomp($time);

  return $time;
}


1;
