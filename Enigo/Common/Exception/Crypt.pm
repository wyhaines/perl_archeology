#!/usr/bin/perl -w
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: $RCSfile: Crypt.pm,v $

=head1 Enigo::Common::Exception::Crypt

I<REVISION:$Revision: 1.1.1.1 $>

I<AUTHOR: $Author: khaines $>

I<DATE_MODIFIED: $Date: 2001/12/17 02:28:37 $>

=head1 PURPOSE:

This exception is thrown by the Enigo::Common::Crypt class when it
fails to create the cryptographic object.

=head1 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################
package Enigo::Common::Exception::Crypt;

use strict;

require Error;
require Enigo::Common::Exception;
use Text::Wrap ();

@Enigo::Common::Exception::Crypt::ISA =
  qw(Enigo::Common::Exception);
$Enigo::Common::Exception::Crypt::VERSION =
  '$Revision: 1.1.1.1 $ ' =~ /\$Revision:\s+([^\s]+)/;


######################################################################
##### Constructor: new
######################################################################

=pod

=head2 CONSTRUCTOR_NAME: new

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 30 JUN 2000>

=head2 PURPOSE:

To create and return a hash reference blessed into
Enigo::Common::Exception::Crypt.  This exception exists
primarily as a superclass and should probably not ever
be thrown directly.

=head2 ARGUMENTS:

Takes one (or two) arguments.  The first is the cipher that is
being used.  The optional second argument is an exit
value for the exception.  This defaults to 1 if not specified.

The arguments may also be passed via a hash reference, with keys of
CIPHER and VALUE.

=head2 RETURNS:

An object blessed into Enigo::Common::Exception::Crypt.

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

    my $param = {CIPHER => '',
                 VALUE => 1};

    if (ref($_[0]) eq 'HASH')
      {
        $param->{CIPHER} = $_[0]->{CIPHER};
        $param->{VALUE} = exists $_[0]->{VALUE} ? $_[0]->{VALUE} :
                                                  $param->{VALUE};
      }
    else
      {
        $param->{CIPHER} = $_[0];
        $param->{VALUE} = defined $_[1] ? $_[1] :  $param->{VALUE};
      }


    local $^W = 0;
    my $text;
    $text = Text::Wrap::wrap('','    ',<<ETXT);
CryptError: Error: An error occured while performing cryptographic
functions with $param->{CIPHER}.

<ERROR_LOCATION/>
ETXT

    return(bless Enigo::Common::Exception->new
           ({TEXT => $text,
             VALUE => $param->{VALUE}}),
           $self);
  }

1;
