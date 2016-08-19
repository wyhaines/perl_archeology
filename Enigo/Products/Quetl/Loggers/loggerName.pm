#!perl
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: loggerName.pm

=head1

I<REVISION: 1>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: 01 Feb 2001>

=head1 PURPOSE:

Returns the logger name of the invoking logger, even if the
responsible logger is back in the call stack several frames.

If called with no arguments, loggerName() will step back
through the call stack until it finds a name that looks like
a logger subroutine.  The check is:

C<$name =~ /_Code$/;>

That should work most of the time, but it is not the most
robust thing in the world, which is why there is another
option.

If loggerName() receives a hash reference with a single
key, DEPTH, with an integer value, it will use that value
in the call to caller() in order to determine the logger
name.

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

sub loggerName {
  my ($param) = paramCheck([DEPTH => 'NO'],@_);

  if (defined $param->{DEPTH}) {
    my ($logger_name) = {caller($param->{DEPTH})}->[3] =~
      /^(.*?)_Code$/;
    return $logger_name;
  } else {
    my $depth = 0;
    while (my $subroutine_name = [caller($depth)]->[3]) {
      last unless defined $subroutine_name;
      my ($logger_name) = $subroutine_name =~ /([^:]*?)_Code$/;
      $depth++;
      next unless defined $logger_name;
      return $logger_name;
    }

    return undef;
  }
}


1;
