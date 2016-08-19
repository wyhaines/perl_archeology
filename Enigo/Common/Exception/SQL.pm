#!/usr/bin/perl -c
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: $RCSfile: SQL.pm,v $

=head1 Enigo::Common::Exception::SQL

I<REVISION:$Revision: 1.1.1.1 $>

I<AUTHOR: $Author: khaines $>

I<DATE_MODIFIED: $Date: 2001/12/17 02:28:37 $>

=head1 PURPOSE:

Enigo::Common::Exception::SQL is the parent to all exceptions dealing with
SQL errors, including exceptions exclusive to the Enigo::Common::SQL::SQL
class.  This exception should only be thrown if there does not exist a
more appropriate, more specific exception subclass to throw.

=head1 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################
package Enigo::Common::Exception::SQL;

use strict;

use Enigo::Common::Exception;

@Enigo::Common::Exception::SQL::ISA =
  qw(Enigo::Common::Exception);
$Enigo::Common::Exception::SQL::VERSION = '$Revision: 1.1.1.1 $ ' =~ /\$Revision:\s+([^\
s]+)/;


######################################################################
##### Constructor: new
######################################################################

=pod

=head2 CONSTRUCTOR_NAME: new

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 11 JUN 2000>

=head2 PURPOSE:

To create and return an object blessed into Enigo::Common::Exception::SQL.

=head2 ARGUMENTS:

Takes one (or two) scalar arguments.  The first is the textual
description of the error that occured.  The optional second
argument is an exit value for the exception.  This defaults to
1 if not specified.

Arguments can also be passed as a hash reference with the keys
TEXT and VALUE.

=head2 RETURNS:

An object blessed into Enigo::Common::Exception::SQL.

=head2 EXAMPLE:

throw Enigo::Common::Exception::SQL('The statement is inefficient');

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
        $param->{VALUE} = defined $_[1] ? $_[1] :  $param->{VALUE};
      }
    my @args;
    return(bless Enigo::Common::Exception->new
           ({TEXT => "SQLError: GeneralError: $param->{TEXT}\n<ERROR_LOCAT
ION/>",
             VALUE => $param->{VALUE}}),
           $self);
  }


1;
