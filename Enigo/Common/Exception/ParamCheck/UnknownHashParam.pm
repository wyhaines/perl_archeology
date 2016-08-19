#!/usr/bin/perl -w
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: $RCSfile: UnknownHashParam.pm,v $

=head1 Enigo::Common::Exception::ParamCheck::UnknownHashParam

I<REVISION:$Revision: 1.1.1.1 $>

I<AUTHOR: $Author: khaines $>

I<DATE_MODIFIED: $Date: 2001/12/17 02:28:37 $>

=head1 PURPOSE:

This exception is thrown by the paramCheck() routine,
Enigo::Common::ParamCheck::ParamCheck, if the list of desired
parameters is ommited.

=head1 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################
package Enigo::Common::Exception::ParamCheck::UnknownHashParam;

use strict;

require Error;
require Enigo::Common::Exception::ParamCheck;
use Text::Wrap ();

@Enigo::Common::Exception::ParamCheck::UnknownHashParam::ISA =
  qw(Enigo::Common::Exception::ParamCheck);
$Enigo::Common::Exception::ParamCheck::UnknownHashParam::VERSION =
  '$Revision: 1.1.1.1 $ ' =~ /\$Revision:\s+([^\s]+)/;


######################################################################
##### Constructor: new
######################################################################

=pod

=head2 CONSTRUCTOR_NAME: new

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 21 JUL 2000>

=head2 PURPOSE:

To create and return a hash reference blessed into
Enigo::Common::Exception::ParamCheck::UnknownHashParam.

=head2 ARGUMENTS:

Takes one, or optionally two, scalar arguments, the key of the unknown
parameter in the parameter hash, and optionally the value of the exception.

These arguments may also be passed via a hash reference, with keys of
KEY and VALUE.

=head2 RETURNS:

An object blessed into Enigo::Common::Exception::ParamCheck::UnknownHashParam.

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

    my $param = {KEY => '',
                 VALUE => 1};

    if (ref($_[0]) eq 'HASH')
      {
        $param->{KEY} = $_[0]->{KEY};
        $param->{VALUE} = exists $_[0]->{VALUE} ? $_[0]->{VALUE} :
                                                  $param->{VALUE};
      }
    else
      {
        $param->{KEY} = $_[0];
        $param->{VALUE} = defined $_[1] ? $_[1] :  $param->{VALUE};
      }


    local $^W = 0;
    my $text;
    $text = Text::Wrap::wrap('','    ',<<ETXT);
ParameterError: UnknownHashParam: a key, $param->{KEY}, was provided in
the hashref passed into paramCheck() that was not defined in the list of
acceptable parameters given to paramCheck().

<ERROR_LOCATION/>
ETXT

    return(bless Enigo::Common::Exception->new
           ({TEXT => $text,
             VALUE => $param->{VALUE}}),
           $self);
  }

1;
