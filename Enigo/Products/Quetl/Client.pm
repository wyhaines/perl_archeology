#!/usr/bin/perl -wc
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: Client.pm

=head1

I<REVISION: .1>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: Jan 03 2001>

=head1 PURPOSE:

Subclasses RPC::PlClient with a provision that overrides
RPC::PlServer::Comm::Write via typeglob voodoo (since the usage
of the Comm::Read and Com::Write methods in the RPC::Pl* stuff
is class specific and thus does not allow for regular subclassing
of the methods) so that the semantics of writing to a RPC
server are changed.  We need to be able to tell the server,
up front, what service (RPC method or subroutine) is being
requested and what user is doing the requesting, so that the
server can properly apply access controls and encryption to
the data stream.

=head1 EXAMPLE:

=head1 TODO:

As usual, test.

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

package Enigo::Products::Quetl::Client;

use strict;

require RPC::PlClient;
require RPC::PlServer::Comm;
use Enigo::Common::ParamCheck qw(paramCheck);
use Data::Dumper;

@Enigo::Products::Quetl::Client::ISA =
  qw(RPC::PlClient RPC::PlServer::Comm);
$Enigo::Products::Quetl::Client::VERSION = '.1';

*RPC::PlServer::Comm::_Write_orig = \&RPC::PlServer::Comm::Write;
*RPC::PlServer::Comm::Write = \&Write;


#If the invocation semantics are consistent with the standard
#RPC::PlServer::Comm::Write semantics, we'll invoke it.  Else
#We do our own custom stuff.
sub Write ($$) {
  my $self = shift;

  my $msg;
  if (ref($_[0]) ne 'HASH') {
    RPC::PlServer::Comm::_Write_orig($self,@_);
  } else {
    my ($param) = paramCheck([SERVICE => 'CD=/^[\w:]+$/',
                  USER => 'AN',
                  DATA => 'U'],@_);
    $param->{DATA} = [] unless $param->{DATA};
    $param->{DATA} = [$param->{DATA}]
      unless (ref($param->{DATA}) eq 'ARRAY');
    my $socket = $self->{socket};

    $param->{DATA} = [$self->{application},
              $self->{version},
              $self->{user},
              $self->{password},
              @{$param->{DATA}}];

    my $encodedMsg = Storable::nfreeze($param->{DATA});

    if ($self->{cipher}) {
      $encodedMsg = $self->{cipher}->encrypt($msg);
    }

    $encodedMsg = join("\n",
              "SERVICE:$param->{SERVICE}",
              "USER:$param->{USER}",
              "DATA:$encodedMsg");
    my($encodedSize) = length($encodedMsg);
    
    if (!$socket->print(pack("N", $encodedSize), $encodedMsg)  ||
        !$socket->flush()) {
        die "Error while writing socket: $!";
    }
  }
}



sub Call ($@) {
  my $self = shift;

  $self->Write(@_);
  my $msg = $self->Read();

  die "Unexpected EOF while waiting for server reply" unless defined($msg);
  die "Server returned error: $$msg" if ref($msg) eq 'SCALAR';
  die "Expected server to return an array ref" unless ref($msg) eq 'ARRAY';
  return @{$msg};
}


sub ClientObject {
  my $self = shift;
  my $class = shift;
  my $method = shift;

  my ($object) = $self->Call({SERVICE => 'NewHandle',
                  USER => $self->{user},
                  DATA => [$class,$method,@_]});

  die "Constructor didn't return an object"
    unless $object =~ /^((?:\w+|\:\:)+)=(\w+)/;
  Enigo::Products::Quetl::Object->new({CLASS => $1,
                        CLIENT => $self,
                        OBJECT => $object,
                        USER => $self->{user}});
}


1;
