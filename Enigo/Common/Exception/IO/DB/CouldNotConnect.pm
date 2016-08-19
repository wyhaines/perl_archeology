#!/usr/bin/perl -c
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: $RCSfile: CouldNotConnect.pm,v $

=head1 Enigo::Common::Exception::IO::DB::CouldNotConnect

I<REVISION:$Revision: 1.1.1.1 $>

I<AUTHOR: $Author: khaines $>

I<DATE_MODIFIED: $Date: 2001/12/17 02:28:37 $>

=head1 PURPOSE:

This class provides an exception for errors incurred when attempting to
connect to a database.

=head1 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################
package Enigo::Common::Exception::IO::DB::CouldNotConnect;

use strict;

require Text::Wrap;
require Enigo::Common::Exception::IO::DB;

@Enigo::Common::Exception::IO::DB::CouldNotConnect::ISA =
  qw(Error Enigo::Common::Exception::IO::DB);
$Enigo::Common::Exception::IO::DB::CouldNotConnect::VERSION = '2000_06_06_15_02';


######################################################################
##### Constructor: new
######################################################################

=pod

=head2 CONSTRUCTOR_NAME: new

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 06 JUN 2000>

=head2 PURPOSE:

To create and to return an object blessed into
Enigo::Common::Exception::IO::DB::CouldNotConnect.

=head2 ARGUMENTS:

Takes either a list of three (or four) scalars, the DSN of the
database, the USER the connection was attempted for, and the
AUTH of the attempted connection, and, optionally, the VALUE
of the exception, or takes a hash reference containing
DSN, USER, AUTH, and, optionally, VALUE keys describing the
connection attempt criteria.

=head2 RETURNS:

An object blessed into Enigo::Common::Exception::IO::DB::CouldNotConnect.

=head2 EXAMPLE:

  throw Enigo::Common::Exception::IO::DB::CouldNotConnect
    ({DSN => 'dbi:Oracle:webdatabase',
      USER => 'lepedius',
      AUTH => 'othello',
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

    my $param = {DSN => '',
         USER => '',
         AUTH => '',
         VALUE => 1};

    if (ref($_[0]) eq 'HASH')
      {
        $param->{DSN} = $_[0]->{DSN};
        $param->{USER} = $_[0]->{USER};
        $param->{AUTH} = $_[0]->{AUTH};
        $param->{VALUE} = exists $_[0]->{VALUE} ? $_[0]->{VALUE} :
                                                  $param->{VALUE};
      }
    else
      {
        $param->{DSN} = $_[0];
        $param->{USER} = $_[1];
        $param->{AUTH} = $_[2];
        $param->{VALUE} = defined $_[3] ? $_[3] : $param->{VALUE};
      }

    my $text = <<ETXT;
Error: CouldNotConnect: Could not connect to $param->{DSN} as $param->{USER}/$param->{AUTH}
in package <ERROR_LOCATION/>

$@
ETXT

    return bless Enigo::Common::Exception->new({TEXT => $text,
                         VALUE => $param->{VALUE}}),
           $self;
  }

