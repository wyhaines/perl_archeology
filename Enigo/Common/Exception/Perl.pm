#!/usr/bin/perl -c
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: $RCSfile: Perl.pm,v $

=head1 Enigo::Common::Exception::Perl

I<REVISION:$Revision: 1.1.1.1 $>

I<AUTHOR: $Author: khaines $>

I<DATE_MODIFIED: $Date: 2001/12/17 02:28:37 $>

=head1 PURPOSE:

This is a generic superclass for all exceptions thrown by overridden
Perl builtins.

=head1 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################
package Enigo::Common::Exception::Perl;

use strict;

require Enigo::Common::Exception;
use Enigo::Common::ParamCheck qw(paramCheck);

@Enigo::Common::Exception::Perl::ISA =
  qw(Enigo::Common::Exception);
$Enigo::Common::Exception::Perl::VERSION = '$Revision: 1.1.1.1 $ ' =~ /\$Revision:\s+([^\s]+)/;


######################################################################
##### Constructor: new
######################################################################

=pod

=head2 CONSTRUCTOR_NAME: new

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 02 Aug 2000>

=head2 PURPOSE:

To return an Enigo::Common::Exception::Perl exception.

=head2 ARGUMENTS:

Takes a single, optional parameter, a scalar containing the value of
the exception.

This can also be pashed via a hash reference with a key of VALUE.

=head2 RETURNS:

An hash blessed into Enigo::Common::Exception::Perl.

=head2 EXAMPLE:

  throw Enigo::Common::Exception::Perl;

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

    my ($param) = paramCheck([VALUE => ['IO',1]],@_);

    my @args;

    return(bless Enigo::Common::Exception->new
       ({TEXT => "PerlError: Error: There was an error with Perl at\n<ERROR_LOCATION/>",
         VALUE => $param->{VALUE}}),
       $self);
  }

1;
