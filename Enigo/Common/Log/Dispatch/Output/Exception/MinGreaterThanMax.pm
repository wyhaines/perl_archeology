#!/usr/bin/perl -c
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: $RCSfile: MinGreaterThanMax.pm,v $

=head1 Enigo::Common::Log::Dispatch::Output::Exception::MinGreaterThanMax

I<REVISION:$Revision: 1.1.1.1 $>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: $Date: 2001/12/17 02:28:37 $>

=head1 PURPOSE:

An exception that is thrown by Enigo::Common::Log::Dispatch::Output
when the minimum logging level is set greater than the maximum
logging level.

=head1 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################
package Enigo::Common::Log::Dispatch::Output::Exception::MinGreaterThanMax;

use strict;

require Enigo::Common::Exception;
use Enigo::Common::ParamCheck qw(paramCheck);

@Enigo::Common::Log::Dispatch::Output::Exception::MinGreaterThanMax::ISA =
  qw(Enigo::Common::Exception);
$Enigo::Common::Log::Dispatch::Output::Exception::MinGreaterThanMax::VERSION =
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

Takes a two mandatory parameters, a scalar containing the minimum
logging level specified, and a scalar containing the maximum logging
level specified.  The constructor also accepts a third, optional
parameter, which is the value of the exception.

These parameters can be passed as a list, or in a hash reference with
keys of MIN, MAX, and VALUE.

=head2 RETURNS:

An hash blessed into
Enigo::Common::Log::Dispatch::Output::Exception::MinGreaterThanMax.

=head2 EXAMPLE:

  throw Enigo::Common::Log::Dispatch::Output::Exception::MinGreaterThanMax
    ({MIN => major,
      MAX => minor});

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

    my ($param) = paramCheck([MIN => 'U',
                  MAX => 'U',
                  VALUE => ['IO',1]],@_);

    my @args;

    $param->{NAME} = ref $param->{NAME} if ref $param->{NAME};
    return(bless Enigo::Common::Exception->new
       ({TEXT => "LogDispatchOutput: MinGreaterThanMax: The minimum supplied logging level, \"$param->{MIN}\", was greater than the maximum supplied logging level, \"$param->{MAX}\".\n<ERROR_LOCATION/>",
         VALUE => $param->{VALUE}}),
       $self);
  }

1;
