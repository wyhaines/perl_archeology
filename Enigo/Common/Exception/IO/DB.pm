#!/usr/bin/perl -c
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: $RCSfile: DB.pm,v $

=head1 Enigo::Common::Exception::IO::DB

I<REVISION:$Revision: 1.1.1.1 $>

I<AUTHOR: $Author: khaines $>

I<DATE_MODIFIED: $Date: 2001/12/17 02:28:37 $>

=head1 PURPOSE:

Provides a general database exception class.  This class should only be
thrown if there does not exist a more appropriate, more specific exception
class to throw.

=head1 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################
package Enigo::Common::Exception::IO::DB;

use strict;

require Enigo::Common::Exception::IO;

@Enigo::Common::Exception::IO::DB::ISA =
  qw(Error Enigo::Common::Exception::IO);
$Enigo::Common::Exception::IO::DB::VERSION = '2000_06_06_14_47';


######################################################################
##### Constructor: new
######################################################################

=pod

=head2 CONSTRUCTOR_NAME: new

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 06 JUN 2000>

=head2 PURPOSE:

To create and return an object blessed into Enigo::Common::Exception::IO::DB.

=head2 ARGUMENTS:

Takes either one (or two) scalar arguments, the TEXT of the error and,
optionally, the VALUE of the exception, or takes a hashref with TEXT
and, optionally, VALUE, as parameters.  Value defaults to 1 if not
provided.

=head2 RETURNS:

An hashref blessed into Enigo::Common::Exception::IO::DB.

=head2 EXAMPLE:

throw Enigo::Common::Exception::IO::DB('The database is down for repairs.');

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

    my $param = {TEXT => '',
         VALUE => 1};

    if (ref($_[0]) eq 'HASH')
      {
    $param->{TEXT} = $_[0]->{TEXT};
        $param->{VALUE} = exists $_[0]->{VALUE} ? $_[0]->{VALUE} :
                                                  $param->{VALUE};
      }
    else
      {
    $param->{TEXT} = $_[0];
        $param->{VALUE} = defined $_[1] ? $_[1] : $param->{VALUE};
      }

    my @args;

    return(bless Enigo::Common::Exception->new
       ({TEXT => "Error: DatabaseError: $param->{TEXT}\n<ERROR_LOCATION/>",
         VALUE => $param->{VALUE}}),
       $self);
  }


1;
