#!/usr/bin/perl -c
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: $RCSfile: CouldNotConnect.pm,v $

=head1 Enigo::Common::Exception::IO::Net::CouldNotConnect

I<REVISION:$Revision: 1.1.1.1 $>

I<AUTHOR: $Author: khaines $>

I<DATE_MODIFIED: $Date: 2001/12/17 02:28:37 $>

=head1 PURPOSE:

This class provides an exception for errors incurred when attempting to
connect to a network entity.

=head1 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################
package Enigo::Common::Exception::IO::Net::CouldNotConnect;

use strict;

require Text::Wrap;
require Enigo::Common::Exception::IO::Net;
use Enigo::Common::ParamCheck qw(paramCheck);

@Enigo::Common::Exception::IO::Net::CouldNotConnect::ISA =
  qw(Error Enigo::Common::Exception::IO::Net);
$Enigo::Common::Exception::IO::Net::CouldNotConnect::VERSION =
    '$Revision: 1.1.1.1 $' =~ /\$Revision:\s+([^\s]+)/;#';


######################################################################
##### Constructor: new
######################################################################

=pod

=head2 CONSTRUCTOR_NAME: new

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 06 JUN 2000>

=head2 PURPOSE:

To create and to return an object blessed into
Enigo::Common::Exception::IO::Net::CouldNotConnect.

=head2 ARGUMENTS:

Takes two, or optionally, three arguments, the ADDRESS that the connect
attempt was made to, the PORT that the connect attempt was made to, and,
optionally, the VALUE of the exception.  These parameters can also be
passed via a hash reference with keys of ADDRESS, PORT, and VALUE.

=head2 RETURNS:

An object blessed into Enigo::Common::Exception::IO::Net::CouldNotConnect.

=head2 EXAMPLE:

  throw Enigo::Common::Exception::IO::Net::CouldNotConnect
    ({ADDRESS => 'www.buffythevampireslayer.com',
      PORT => 80,
      VALUE => 69});

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub new
  {
    my ($self) = shift;

    my ($param) = paramCheck([ADDRESS => 'CD=/^(?:\d|\.|-|[a-zA-Z])+$/',
                              PORT => 'I',
                              VALUE => 'IO'],@_);
    $param->{VALUE} = 0 unless $param->{VALUE};

    my $text = <<ETXT;
Error: CouldNotConnect: Could not connect to $param->{ADDRESS} on port $param->{PORT}
in package <ERROR_LOCATION/>

$@
ETXT

    return bless Enigo::Common::Exception->new({TEXT => $text,
                         VALUE => $param->{VALUE}}),
           $self;
  }

1;
