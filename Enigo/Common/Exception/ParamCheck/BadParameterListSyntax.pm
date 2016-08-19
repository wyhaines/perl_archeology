#!/usr/bin/perl -w
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: $RCSfile: BadParameterListSyntax.pm,v $

=head1 Enigo::Common::Exception::ParamCheck::BadParameterListSyntax

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
package Enigo::Common::Exception::ParamCheck::BadParameterListSyntax;

use strict;

require Error;
require Enigo::Common::Exception::ParamCheck;
use Text::Wrap ();

@Enigo::Common::Exception::ParamCheck::BadParameterListSyntax::ISA =
  qw(Enigo::Common::Exception::ParamCheck);
$Enigo::Common::Exception::ParamCheck::BadParameterListSyntax::VERSION =
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
Enigo::Common::Exception::ParamCheck::BadParameterListSyntax.

=head2 ARGUMENTS:

Takes only a single optional argument, the value of the exception.

This argument may also be passed via a hash reference, with the key of
VALUE.

=head2 RETURNS:

An object blessed into Enigo::Common::Exception::ParamCheck::BadParameterListSyntax.

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

    my $param = {VALUE => 1};

    if (ref($_[0]) eq 'HASH')
      {
        $param->{VALUE} = exists $_[0]->{VALUE} ? $_[0]->{VALUE} :
                                                  $param->{VALUE};
      }
    else
      {
        $param->{VALUE} = defined $_[0] ? $_[0] :  $param->{VALUE};
      }


    local $^W = 0;
    my $text;
    $text = Text::Wrap::wrap('','    ',<<ETXT);
ParameterError: BadParameterListSyntax: syntax error in the parameter list
that was passed to ParamCheck.  See the perldoc in Enigo::Common::ParamCheck
for more information.

<ERROR_LOCATION/>
ETXT

    return(bless Enigo::Common::Exception->new
           ({TEXT => $text,
             VALUE => $param->{VALUE}}),
           $self);
  }

1;
