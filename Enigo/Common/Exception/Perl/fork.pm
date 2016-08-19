#!/usr/bin/perl -c
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: $RCSfile: fork.pm,v $

=head1 Enigo::Common::Exception::Perl::fork

I<REVISION:$Revision: 1.1.1.1 $>

I<AUTHOR: $Author: khaines $>

I<DATE_MODIFIED: $Date: 2001/12/17 02:28:37 $>

=head1 PURPOSE:

This exception is thrown by Enigo::Common::Override::PerlExceptions::forkl
if the fork() call fails.

=head1 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################
package Enigo::Common::Exception::Perl::fork;

use strict;

require Enigo::Common::Exception::Perl;
use Enigo::Common::ParamCheck qw(paramCheck);

@Enigo::Common::Exception::Perl::fork::ISA =
  qw(Enigo::Common::Exception::Perl);
$Enigo::Common::Exception::Perl::fork::VERSION = '$Revision: 1.1.1.1 $ ' =~ /\$Revision:\s+([^\s]+)/;


######################################################################
##### Constructor: new
######################################################################

=pod

=head2 CONSTRUCTOR_NAME: new

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 02 Aug 2000>

=head2 PURPOSE:

To return an Enigo::Common::Exception::Perl::fork exception.

=head2 ARGUMENTS:

Takes a single, optional parameter, a scalar containing the value of
the exception.

This can also be pashed via a hash reference with a key of VALUE.

=head2 RETURNS:

An hash blessed into Enigo::Common::Exception::Perl::fork.

=head2 EXAMPLE:

  throw Enigo::Common::Exception::Perl::fork();

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
       ({TEXT => "PerlError: fork: The call to fork() failed at\n<ERROR_LOCATION/>",
         VALUE => $param->{VALUE}}),
       $self);
  }

1;
