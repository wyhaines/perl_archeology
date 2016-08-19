#!/usr/bin/perl -wc
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: $RCSfile: RPCServer.pm,v $

=head1 Enigo::Products::RPCServer::RPCServer;

I<REVISION: $Revision: 1.1.1.1 $>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: 6 Jan 2001>

=head1 PURPOSE:

This class is a subclass of RPC::PlServer for the RPC server.

=head1 TODO:

Test test test.

Convert use of 'die' to use of exceptions.

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

package Enigo::Products::RPCServer::RPCServer;

use strict;
use Enigo::Common::Exception qw(:IO);
use Enigo::Common::ParamCheck qw(paramCheck);
use Data::Dumper;
use POSIX qw(:signal_h);

require RPC::PlServer;
@Enigo::Products::RPCServer::RPCServer::ISA = qw(RPC::PlServer);
$Enigo::Products::RPCServer::RPCServer::VERSION = '1.0';

#####
#use Enigo::Products::RPCServer::Comm;
#####
*RPC::PlServer::Comm::_Read_orig = \&RPC::PlServer::Comm::Read;
*RPC::PlServer::Comm::Read = \&Read;



######################################################################
##### Constructor: new
######################################################################

=pod

=head2 CONSTRUCTOR_NAME: new

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 6 Jan 2001>

=head2 PURPOSE:

Create a new blessed hash and return it.

=head2 ARGUMENTS:

As per RPC::PlServer, except that there are two additional
arguments in the hash that are expected, DISPATCHER and
SERVICES.

DISPATCHER should contain an instance of Log::Dispatch with
which the RPCServer can log to.

=head2 THROWS:

nothing.

=head2 RETURNS:

A blessed hash.

=head2 EXAMPLE:

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub new ($$,$) {
  my ($proto) = shift;
  my $param = $_[0];
  my ($class) = ref($proto) || $proto;
  my $self = $class->SUPER::new(@_);
  bless($self,$class);
  $self->{DISPATCHER} = $param->{DISPATCHER};
  $self->{SERVICES} = $param->{SERVICES};

  return $self;
}



######################################################################
##### Method: Write
######################################################################

=pod

=head2 METHOD_NAME: Write

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 6 Jan 2001>

=head2 PURPOSE:

Overrides RPC::PlServer::Comm::Write(), but is currently just
an unused hook intended for possible later expansion.

=head2 ARGUMENTS:

As RPC::PlServer::Comm::Write()

=head2 THROWS:

nothing

=head2 RETURNS:

As RPC::PlServer::Comm::Write()

=head2 EXAMPLE:

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub Write ($$) {
  my $self = shift;

  $self->SUPER::Write(@_);
}



######################################################################
##### Method: Read
######################################################################

=pod

=head2 METHOD_NAME: Read

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 6 Jan 2001>

=head2 PURPOSE:

Reads RPC communications from a socket.  If the data that is read
looks like our custom format:

  SERVICE:service1,service2,service3,..serviceN
  USER:username
  DATA:frozen data structure

then we read it our way.  Otherwise, we read it just as the
superclass would.

=head2 ARGUMENTS:

nothing

=head2 THROWS:

nothing

=head2 RETURNS:

The message that was read from the socket.

=head2 EXAMPLE:

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub Read ($) {
  my $self = shift;
  my $socket = $self->{'socket'};
  my $result;

  my($encodedSize, $readSize, $blockSize);
  $readSize = 4;
  $encodedSize = '';
  while ($readSize > 0) {
    my $result = $socket->read($encodedSize, $readSize,
                   length($encodedSize));
    if (!$result) {
      return undef if defined($result);
      die "Error while reading socket: $!";
    }
    $readSize -= $result;
  }
  $encodedSize = unpack("N", $encodedSize);
#  my $max = $self->{maxmessage} ? $self->{maxmessage} : 65536;
#  die "Maximum message size of $max exceeded, use option 'maxmessage' to"
#    . " increase" if $encodedSize > $max;
  $readSize = $encodedSize;

  my $msg = '';
  my $rs = $readSize;
  while ($rs > 0) {
    my $result = $socket->read($msg, $rs, length($msg));
        if (!$result) {
      die "Unexpected EOF" if defined $result;
      die "Error while reading socket: $!";
        }
    $rs -= $result;
  }

  if ($msg =~ /^SERVICE:(.*?)\nUSER:(.*?)\nDATA:(.*)$/s) {
    $self->{SERVICE} = $1;
    $self->{USER} = $2;
    $msg = $3;
    $self->{DISPATCHER}->log(level => 'debug',
                 message => "$$: Communications from $2 for service $1\n");
  } else {
    $self->{SERVICE} = undef;
    $self->{USER} = undef;
  }

  if ($self->{SERVICE}) {
    my $client = $self->_matchMask();
    my $encryption_algorithm;
    my $encryption_key;

    if ($self->{USER}) {
      $encryption_algorithm = $self->{SERVICES}->{$self->{SERVICE}}->
    {CLIENTS}->{$client->{MASK}}->
      {USERS}->{$self->{USER}}->{ENCRYPTION_ALGORITHM};
      $encryption_key = $self->{SERVICES}->{$self->{SERVICE}}->
    {CLIENTS}->{$client->{MASK}}->
      {USERS}->{$self->{USER}}->{ENCRYPTION_KEY};
    } else {
      $encryption_algorithm = $self->{SERVICES}->{$self->{SERVICE}}->
    {CLIENTS}->{$client->{MASK}}->
      {ENCRYPTION_ALGORITHM};
      $encryption_key = $self->{SERVICES}->{$self->{SERVICE}}->
    {CLIENTS}->{$client->{MASK}}->
      {ENCRYPTION_KEY};
    }

    if (defined $encryption_algorithm and
    defined $encryption_key) {

      my $cipher;
      unless ($cipher =
          $self->{CIPHERS}->{$encryption_algorithm}->{encryption_key})
    {
      eval {
        $cipher =
          $self->{CIPHERS}->{$encryption_algorithm}->{encryption_key} =
        Crypt::CBC->new($encryption_key,$encryption_algorithm);
      }
    }
      $msg = $cipher->decrypt($msg)
    if $cipher;
    }
  }

  return Storable::thaw($msg);
}



######################################################################
##### Method: Accept
######################################################################

=pod

=head2 METHOD_NAME: Accept

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 6 Jan 2001>

=head2 PURPOSE:

Determines whether to accept a connection or not.  Under
RPC::PlServer, authentication is done at this step.  However,
under this class, we simply accept all connections, and actual
authentication is done only after the client has requested
some service from the server.

=head2 ARGUMENTS:

nothing

=head2 THROWS:

nothing

=head2 RETURNS:

1;

=head2 EXAMPLE:

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub Accept ($) {
  my $self = shift;

  my $msg = $self->Read();
  die "Unexpected EOF from client" unless defined $msg;
  die "Login message: Expected array, got $msg" unless ref($msg) eq 'ARRAY';

  $self->{DISPATCHER}->log(level => 'debug',
               message => "$$: Accepting the connection\n");

  $Enigo::Products::RPCServer::Server::self->_initDatabase();

  $self->Write([1, "Welcome!"]);

  return 1;
}

sub AcceptApplication ($$) {
  return 1;
}



sub _matchMask {
  my $self = shift;

  my $name;
  my $aliases;
  my $addrtype;
  my $length;
  my @addrs;

  if ($self->{proto} eq 'unix') {
    ($name,$aliases,$addrtype,$length,@addrs) =
      ('localhost','',Socket::AF_INET(),
       length(Socket::IN_ADDR_ANY()),
       Socket::inet_aton('127.0.0.1'));
  } else {
    ($name,$aliases,$addrtype,$length,@addrs) =
      gethostbyaddr($self->{socket}->peeraddr(),Socket::AF_INET());
  }

  my @patterns = @addrs ?
    map {Socket::inet_ntoa($_)} @addrs :
      $self->{socket}->peerhost();
  push(@patterns,$name) if ($name);
  push(@patterns,split(/ /,$aliases)) if $aliases;

  my $found;

 OUTER: foreach my $client
    (values(%{$self->{SERVICES}->{$self->{SERVICE}}->{CLIENTS}})) {
      if (!$client->{MASK}) {
    $found = $client;
    last;
      }
      my $masks = ref($client->{MASK}) ?
    $client->{MASK} : [ $client->{MASK}];

      my $lock;

      foreach my $mask (@$masks) {
    foreach my $alias (@patterns) {
      $self->{DISPATCHER}->log
        (level => 'debug',
         message => "$$: Checking access; mask=$mask, alias=$alias\n");
      if ($alias =~ /$mask/) {
        $found = $client;
        $self->{DISPATCHER}->log
          (level => 'debug',
           message => "$$: Host match found; mask=$mask, alias=$alias\n");
        last OUTER;
      }
    }
      }
    }

  return $found ? $found : undef;
}



sub AcceptUser ($$$) {
  my $self = shift;
  my ($param) = paramCheck([USER => 'U',
                PASSWORD => 'U'],@_);
  my $client = $self->_matchMask();
  return undef unless $client;
  return 1 unless $client->{USERS};

  $self->{DISPATCHER}->log
    (level => 'debug',
     message => "$$: Full client list to search:\n" . Dumper($client->{USERS}));

  foreach my $user (values(%{$client->{USERS}})) {
    $self->{DISPATCHER}->log
      (level => 'debug',
       message => "$$: Comparing user $param->{USER} to $user->{NAME}\n");
    next unless ($user->{NAME} eq $param->{USER});

    $self->{DISPATCHER}->log
      (level => 'debug',
       message => "$$: Comparing password $param->{PASSWORD} to $user->{PASSWORD}\n");
      return $user->{PASSWORD} eq $param->{PASSWORD} ?
    eval {$self->{authorized_user} = $user} :
      undef;
  }
  return undef;
}



sub validate {
  my $self = shift;
  my $param;
eval {
  ($param) = paramCheck([MESSAGE => 'U'],@_);
};
  #Uh, don't ask.  I seem to be exposing some WIERD variable persistance
  #bugs.  If I don't make this dumper call, the info in $param seems to
  #vanish on me.  I don't like this one little bit....
  Dumper($param->{MESSAGE});
  my $app = $param->{MESSAGE}->[0];
  my $version = $param->{MESSAGE}->[1];
  my $user = $param->{MESSAGE}->[2];
  my $password = $param->{MESSAGE}->[3];

  if (!$self->AcceptApplication($app)) {
    $self->RPC::PlServer::Comm::Write
      ([0, "This is a " . ref($self) . " server, go away!"]);
    return 0;
  }
  if (!$self->AcceptVersion($version)) {
    $self->RPC::PlServer::Comm::Write
      ([0, "Sorry, but I am not running version $version."]);
    return 0;
  }
  my $result;
  if (!($result = $self->AcceptUser($user, $password))) {
    $self->RPC::PlServer::Comm::Write
      ([0, "User $user is not permitted to connect."]);
    return 0;
  }
}


sub Run ($) {
  my $self = shift;
  my $socket = $self->{socket};

  my $full_set = POSIX::SigSet->new(SIGHUP,
                    SIGTERM,
                    SIGQUIT,
                    SIGINT);

  while (!$self->Done()) {
    my $msg = $self->Read();
    last unless defined($msg);
    $self->validate({MESSAGE => $msg});

    my $app = $msg->[0];
    my $version = $msg->[1];
    my $user = $msg->[2];
    my $password = $msg->[3];

    splice(@{$msg},0,4);

    my($error, $command);
    if ($self->{SERVICE}) {
      $command = $self->{SERVICE};
    } else {
      $command = shift @{$msg};
    }
    unless ($command) {
      $error = "Expected method name";
    } else {
      if ($self->{methods}) {
    my $class = $self->{methods}->{$app};
    if (!$class  ||  !$class->{$command}) {
      $error = "Not permitted for method $command of class "
        . ref($self);
    }
      }
      if (!$error) {
    $self->Debug("Client executes method $command");
    no strict 'refs';
    my $call = join('::',
            $app,
            $command);

    sigprocmask(SIG_BLOCK,$full_set);
    my @result = eval {&{$call}($self,@{$msg})};
    if ($@) {
      $error = "Error:Failed to execute $call: $@";
    } else {
      $self->RPC::PlServer::Comm::Write(\@result);
    }
    sigprocmask(SIG_UNBLOCK,$full_set);
      }
    }
    if ($error) {
      $self->RPC::PlServer::Comm::Write(\$error);
    }
  }
  $Enigo::Products::RPCServer::SQL->get_dbh()->disconnect();
}


1;
