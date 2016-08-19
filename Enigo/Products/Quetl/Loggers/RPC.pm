#!perl
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: RPC.pm

=head1

I<REVISION: 1>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: 01 Feb 2001>

=head1 PURPOSE:

Issues an RPC call to a single server.  RPC() takes a hash reference
with, at a minimum, keys for ADDRESS, SERVICE, USER, and PASSWORD.
Other options that are accepted are: PORT, VERSION, TIMEOUT,
MAXMESSAGE, COMPRESSION, ENCRYPTION_ALGORITHM, ENCRYPTION_KEY,
and ARGS.  All accept scalar values except for ARGS, which expects
an array reference containing the array of arguments to pass to
the RPC function.

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

sub RPC {
  my ($param) = paramCheck([ADDRESS => 'U',
                SERVICE => 'U',
                PORT => ['N',4457],
                USER => 'U',
                PASSWORD => 'U',
                VERSION => ['U','1.0'],
                TIMEOUT => ['U',''],
                MAXMESSAGE => ['N',10000000],
                COMPRESSION => ['N',0],
                ENCRYPTION_ALGORITHM => ['U',''],
                ENCRYPTION_KEY => ['U',''],
                ARGS => 'AR'],@_);

  my $args = $param->{ARGS};
  delete($param->{ARGS});
  return $Enigo::Products::Quetl::self->_make_RPC_call({SERVER => $param,
                            ARGS => $args});
}


1;
