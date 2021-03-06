#!/usr/bin/perl -c
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: $RCSfile: General.pm,v $

=head1 Enigo::Common::Exception::General

I<REVISION:$Revision: 1.1.1.1 $>

I<AUTHOR: $Author: khaines $>

I<DATE_MODIFIED: $Date: 2001/12/17 02:28:37 $>

=head1 PURPOSE:

This class represents some sort of general error.  It should
only be thrown in the unlikely case that a more specific exception
class does not exist for the error in question.

=head1 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################
package Enigo::Common::Exception::General;

use strict;

require Enigo::Common::Exception;

@Enigo::Common::Exception::General::ISA =
  qw(Enigo::Common::Exception);
$Enigo::Common::Exception::General::VERSION = '$Revision: 1.1.1.1 $ ' =~ /\$Revision:\s+([^\s]+)/;


######################################################################
##### Constructor: new
######################################################################

=pod

=head2 CONSTRUCTOR_NAME: new

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 22 JUN 2000>

=head2 PURPOSE:

To return an Enigo::Common::Exception::General exception.

=head2 ARGUMENTS:

Takes either two (or three) scalar arguments, the type of error,
the textual description of the error and, optionally, the VALUE of the
exception, or takes a hashref with TYPE, TEXT, and, optionally, VALUE,
as parameters.  Value defaults to 1 if not provided.

=head2 RETURNS:

An hash blessed into Enigo::Common::Exception::General.

=head2 EXAMPLE:

throw Enigo::Common::Exception::General
    ({TYPE => 'TempLimitExceeded',
      TEXT => "The temperature in the machine room is excessive ($temp).",
      VALUE => 37});

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

    my $param = {TYPE => '',
         TEXT => '',
         VALUE => 1};

    if (ref($_[0]) eq 'HASH')
      {
    $param->{TYPE} = $_[0]->{TYPE};
    $param->{TEXT} = $_[0]->{TEXT};
        $param->{VALUE} = exists $_[0]->{VALUE} ? $_[0]->{VALUE} :
                                              $param->{VALUE};
      }
    else
      {
    $param->{TYPE} = $_[0];
    $param->{TEXT} = $_[1];
        $param->{VALUE} = defined $_[2] ? $_[2] :  $param->{VALUE};
      }

    my @args;

    return(bless Enigo::Common::Exception->new
       ({TEXT => "GeneralError: $param->{TYPE}: $param->{TEXT}\n<ERROR_LOCATION/>",
         VALUE => $param->{VALUE}}),
       $self);
  }


1;
