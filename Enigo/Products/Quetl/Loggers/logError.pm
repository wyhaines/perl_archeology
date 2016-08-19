#!perl
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: logError.pm

=head1

I<REVISION: 1>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: 01 Feb 2001>

=head1 PURPOSE:

Logs an error to the Quetl details db.  It expects to receive
a hash reference with two keys, NAME and DETAILS.

NAME is the logger name to record the error under.  DETAILS
are any details about the error that are to be recorded.

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

sub logError {
  my ($param) = paramCheck([NAME => 'UO',
                DETAILS => 'U'],@_);

  my $name = $param->{NAME} ?
    $param->{NAME} : loggerName();
  $Enigo::Products::Quetl::self->_log({NAME => $name,
                       ACTION => 'ERROR',
                       TIME => time(),
                       DETAILS => $param->{DETAILS},
                       STATE => 'e'});
}


1;
