#!perl
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: writeLog.pm

=head1

I<REVISION: 1>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: 01 Feb 2001>

=head1 PURPOSE:

Writes an entry to the RPCServer log.

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

sub writeLog {
  my ($param) = paramCheck([LEVEL => ['AN','notice'],
                            MESSAGE => ['U','<time/>']],@_);
 
  my $time = POSIX::asctime(localtime(time));
  chomp($time);
  $param->{MESSAGE} =~ s|<time/>|$time|g;
 
  $Enigo::Products::RPCServer::Server::Dispatcher->log
    (level => $param->{LEVEL},
     message => "$$: Service: $param->{MESSAGE}");                                           
}


1;
