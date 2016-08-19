#!/usr/bin/perl -w
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: $RCSfile: InvalidDefaultDBH.pm,v $

=head1 Enigo::Common::Exception::SQL::InvalidDefaultDBH

I<REVISION:$Revision: 1.1.1.1 $>

I<AUTHOR: $Author: khaines $>

I<DATE_MODIFIED: $Date: 2001/12/17 02:28:37 $>

=head1 PURPOSE:

This exception is thrown by the Enigo::Common::SQL::SQL class when a call
to get_dbh() fails.

=head1 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################
package Enigo::Common::Exception::SQL::InvalidDefaultDBH;

use strict;

require Error;
require Enigo::Common::Exception::SQL;
use Text::Wrap ();

@Enigo::Common::Exception::SQL::InvalidDefaultDBH::ISA =
  qw(Enigo::Common::Exception::SQL);
$Enigo::Common::Exception::SQL::InvalidDefaultDBH::VERSION =
  '$Revision: 1.1.1.1 $ ' =~ /\$Revision:\s+([^\s]+)/;


######################################################################
##### Constructor: new
######################################################################

=pod

=head2 CONSTRUCTOR_NAME: new

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 22 JUN 2000>

=head2 PURPOSE:

To create and return a hash reference blessed into
Enigo::Common::Exception::SQL::InvalidDefaultDBH.

=head2 ARGUMENTS:

Takes two (or three) arguments.  The first is the DSN of the database
that was to be set as the default database.  The second is the user
of the default connection.  The option third argument is an exit
value for the exception.  This defaults to 1 if not specified.

The arguments may also be passed via a hash reference, with keys of
DSN, USER, and VALUE.

=head2 RETURNS:

An object blessed into Enigo::Common::Exception::SQL::InvalidDefaultDBH.

=head2 EXAMPLE:

none

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
                 VALUE => 1};

    if (ref($_[0]) eq 'HASH')
      {
        $param->{DSN} = $_[0]->{DSN};
        $param->{USER} = $_[0]->{USER};
        $param->{VALUE} = exists $_[0]->{VALUE} ? $_[0]->{VALUE} :
                                                  $param->{VALUE};
      }
    else
      {
        $param->{DSN} = $_[0];
        $param->{USER} = $_[1];
        $param->{VALUE} = defined $_[2] ? $_[2] :  $param->{VALUE};
      }


    local $^W = 0;
    return(bless Enigo::Common::Exception->new
           ({TEXT => Text::Wrap::wrap('','    ',"SQLError: InvalidDefaultDBH: there is no current database handle to match $param->{USER}\@$param->{DSN}.\n<ERROR_LOCATION/>"),
             VALUE => 1}),
           $self);
  }

1;
