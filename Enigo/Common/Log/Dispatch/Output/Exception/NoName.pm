#!/usr/bin/perl -c
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: $RCSfile: NoName.pm,v $

=head1 Enigo::Common::Log::Dispatch::Output::Exception::NoName

I<REVISION:$Revision: 1.1.1.1 $>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: $Date: 2001/12/17 02:28:37 $>

=head1 PURPOSE:

An exception that is thrown by Enigo::Common::Log::Dispatch::Output
when a name for a logging object is not supplied.

=head1 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################
package Enigo::Common::Log::Dispatch::Output::Exception::NoName;

use strict;

require Enigo::Common::Exception;
use Enigo::Common::ParamCheck qw(paramCheck);

@Enigo::Common::Log::Dispatch::Output::Exception::NoName::ISA =
  qw(Enigo::Common::Exception);
$Enigo::Common::Log::Dispatch::Output::Exception::NoName::VERSION =
  '$Revision: 1.1.1.1 $ ' =~ /\$Revision:\s+([^\s]+)/;


######################################################################
##### Constructor: new
######################################################################

=pod

=head2 CONSTRUCTOR_NAME: new

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 27 Sept 2001>

=head2 PURPOSE:

To return an exception object.

=head2 ARGUMENTS:

Takes a single mandatory parameter, a scalar containing either the
name of the object, or an actual reference to the object.  The
constructor also accepts a second, optional parameter, which is the
value of the exception.

These parameters can be passed as a list, or in a hash reference with
keys of NAME and VALUE.

=head2 RETURNS:

An hash blessed into
Enigo::Common::Log::Dispatch::Output::Exception::NoName.

=head2 EXAMPLE:

  throw Enigo::Common::Log::Dispatch::Output::Exception::NoName
    ({NAME => $self});

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

    my ($param) = paramCheck([NAME => 'U',
                  VALUE => ['IO',1]],@_);

    my @args;

    $param->{NAME} = ref $param->{NAME} if ref $param->{NAME};
    return(bless Enigo::Common::Exception->new
       ({TEXT => "LogDispatchOutput: NoName: No name was supplied for $param->{NAME} object.\n<ERROR_LOCATION/>",
         VALUE => $param->{VALUE}}),
       $self);
  }

1;
