#!/usr/bin/perl -wc
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: $RCSfile: NotFound.pm,v $

=head1 

I<REVISION:$Revision: 1.1.1.1 $>

I<AUTHOR: $Author: khaines $>

I<DATE_MODIFIED: $Date: 2001/12/17 02:28:37 $>

=head1 PURPOSE:

This is an exception class for use with the Error package by Graham Barr.
It should be thrown when a filesystem access was attempted, but the target
of that access did not exist.

=head1 EXAMPLE:

=head1 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

package Enigo::Common::Exception::IO::File::NotFound;


use strict;

use Enigo::Common::Exception qw(:IO);
use Enigo::Common::Exception::IO::File;
use Enigo::Common::ParamCheck qw(paramCheck);

@Enigo::Common::Exception::IO::File::NotFound::ISA =
  qw(Enigo::Common::Exception::IO::File);
$Enigo::Common::Exception::IO::File::NotFound::VERSION =
  '$Revision: 1.1.1.1 $ ' =~ /\$Revision:\s+([^\s]+)/;



######################################################################
##### Constructor: new
######################################################################

=pod

=head2 CONSTRUCTOR_NAME: new

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 15 Sept 2000>

=head2 PURPOSE:

Returns a hash blessed as a file not found exception.

=head2 ARGUMENTS:

Takes one, or optionally, two scalar arguments, the path of the
filesystem entity which was not found and the value of the
exception.  These can be passed via a list, in the order above, or
in a hash reference with keys of PATH and VALUE.

=head2 THROWS:

=head2 RETURNS:

A blessed hashref.

=head2 EXAMPLE:

  throw Enigo::Common::Exception::IO::File::NotFound
    ('/var/log/mylog.log');

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub new {
  my ($self) = shift;
  my ($param) = paramCheck([PATH => 'U',
                VALUE => ['IO',1]],@_);
  
  my @args;
  
  return(bless Enigo::Common::Exception->new
     ({TEXT => "Error: FileNotFound: $param->{PATH} could not be found.\n<ERROR_LOCATION/>",
       VALUE => $param->{VALUE}}),
     $self);
}

1;
