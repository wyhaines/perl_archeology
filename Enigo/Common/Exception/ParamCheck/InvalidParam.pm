#!/usr/bin/perl -w
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: $RCSfile: InvalidParam.pm,v $

=head1 Enigo::Common::Exception::ParamCheck::InvalidParam

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
package Enigo::Common::Exception::ParamCheck::InvalidParam;

use strict;

require Error;
require Enigo::Common::Exception::ParamCheck;
use Text::Wrap ();

@Enigo::Common::Exception::ParamCheck::InvalidParam::ISA =
  qw(Enigo::Common::Exception::ParamCheck);
$Enigo::Common::Exception::ParamCheck::InvalidParam::VERSION =
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
Enigo::Common::Exception::ParamCheck::InvalidParam.

=head2 ARGUMENTS:

Takes three, or optionally four, scalar arguments.  The first is the key
to the param that had the invalid value.  The second is the param value that
was invalid.  The third is the expected type of the parameter, and the
optional fourth is the value of the exception.

These parameters can also be passed via a hash reference, with the keys of
KEY, PARAM_VALUE, TYPE, and VALUE.

=head2 RETURNS:

An object blessed into Enigo::Common::Exception::ParamCheck::InvalidParam.

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
                 PARAM_VALUE => '',
                 TYPE => '',
                 VALUE => 1};

    if (ref($_[0]) eq 'HASH')
      {
        $param->{KEY} = $_[0]->{KEY};
        $param->{PARAM_VALUE} = $_[0]->{PARAM_VALUE};
        $param->{TYPE} = $_[0]->{TYPE};
        $param->{VALUE} = exists $_[0]->{VALUE} ? $_[0]->{VALUE} :
                                                  $param->{VALUE};
      }
    else
      {
        $param->{KEY} = $_[0];
        $param->{PARAM_VALUE} = $_[1];
        $param->{TYPE} = $_[2];
        $param->{VALUE} = defined $_[3] ? $_[3] :  $param->{VALUE};
      }


    local $^W = 0;
    my $type_text;

    {
      $param->{TYPE} =~ /^CD(?:O)?\s*=\s*(.*)$/ && do
        {
          $type_text = "something that satisfies $1";
          last;
        };
      $param->{TYPE} =~ /^ECR/ && do
        {
          $type_text = 'an executable code reference that returns a true value';
          last;
        };
      $param->{TYPE} =~ /^CR/ && do
        {
          $type_text = 'a code reference';
          last;
        };
      $param->{TYPE} =~ /^GR/ && do
        {
          $type_text = 'a glob reference';
          last;
        };
      $param->{TYPE} =~ /^HR/ && do
        {
          $type_text = 'a hash reference';
          last;
        };
      $param->{TYPE} =~ /^AR/ && do
        {
          $type_text = 'an array reference';
          last;
        };
      $param->{TYPE} =~ /^SR/ && do
        {
          $type_text = 'a scalar reference';
          last;
        };
      $param->{TYPE} =~ /^AN/ && do
        {
          $type_text = 'an alphanumeric (plus whitespace) scalar';
          last;
        };
      $param->{TYPE} =~ /^UR/ && do
        {
          $type_text = 'any type of reference';
          last;
        };
      $param->{TYPE} =~ /^U/ && do
        {
          #This one should actually never appear....
          $type_text = 'any scalar data';
          last;
        };
      $param->{TYPE} =~ /^A/ && do
        {
          $type_text = 'an alphabetic (plus whitespace) scalar';
          last;
        };
      $param->{TYPE} =~ /^I/ && do
        {
          $type_text = 'an integer value';
          last;
        };
      $param->{TYPE} =~ /^N/ && do
        {
          $type_text = 'a numeric value';
          last;
        };
      $param->{TYPE} =~ /^RR/ && do
        {
          $type_text = 'a reference to a reference';
          last;
        };
      }
    my $text;
    $text = Text::Wrap::wrap('','    ',<<ETXT);
ParameterError: InvalidParam: the parameter ($param->{KEY}) with a value of:

$param->{PARAM_VALUE}

is invalid.  The parameter's value must be $type_text.

<ERROR_LOCATION/>
ETXT

    return(bless Enigo::Common::Exception->new
           ({TEXT => $text,
             VALUE => $param->{VALUE}}),
           $self);
  }

1;
