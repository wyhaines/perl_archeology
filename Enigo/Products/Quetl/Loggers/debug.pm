#!perl
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: debug.pm

=head1

I<REVISION: 1>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: 01 Feb 2001>

=head1 PURPOSE:

Writes a debugging message.  By default, writes both to the
logfile and to STDERR.  This can be overriden with arguments
to debug, however.  At a minimum, debug expects to receive
a hash reference with one argument, CLVAR.

CLVAR should contains a reference to the %CLVAR hash.

Other accepted arguments are:

ID: This is the name of the task that is calling debug.  If
unspecified, the caller as identified by 'caller(1)' is used.  The
ID must exist within the comma seperated list of values contained
in %CLVAR{debug}.

STDERR: If true, the debugging message will be output to STDERR.
It defaults to true.

LOG: If true, the debugging message will be sent to the RPCServer
log dispatcher.  It defaults to true.

MESSAGE: The debugging message.  It defaults to the current time.

LEVEL: The numeric loglevel of this message.  Use 0 for the most
general messages, and increasing numbers for more detailed
messages.  This defaults to 0.

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

sub debug {
  my ($param) = paramCheck([ID => 'UO',
                STDERR => ['U',1],
                LOG => ['U',1],
                CLVAR => 'HR',
                            MESSAGE => ['U','<time/>'],
                            LEVEL => ['N',0]],@_);

  my $debug = $param->{CLVAR}->{debug} ?
    $param->{CLVAR}->{debug} : $param->{CLVAR}->{DEBUG};
  $param->{ID} = $param->{ID} ?
    $param->{ID} : [caller(1)]->[3];

  my $id;
  my $level;
  return undef unless (($id,$level) = ",$debug," =~ /,($param->{ID}):(\d+)?,/);
  $level = $level ? $level : 0;
  return undef unless ($level >= $param->{LEVEL});

  my $time = sfmt_time();
  $param->{MESSAGE} =~ s|<time/>|$time|g;

  my $message = "$$: Debugging $id : $param->{MESSAGE}";

  $Enigo::Products::Quetl::Dispatcher->log
    (level => $param->{LEVEL},
     message => $message)
      if $param->{LOG};

  print STDERR "$message\n" if $param->{STDERR};

  return undef;
}


1;
