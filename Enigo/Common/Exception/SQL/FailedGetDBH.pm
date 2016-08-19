#!/usr/bin/perl -w
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: $RCSfile: FailedGetDBH.pm,v $

=head1 Enigo::Common::Exception::SQL::FailedGetDBH

I<REVISION:$Revision: 1.1.1.1 $>

I<AUTHOR: $Author: khaines $>

I<DATE_MODIFIED: $Date: 2001/12/17 02:28:37 $>

=head1 PURPOSE:

This exception is thrown by the Enigo::Common::SQL::SQL class when a call
to get_dbh() fails.

=head1 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################
package Enigo::Common::Exception::SQL::FailedGetDBH;

use strict;

require Error;
require Enigo::Common::Exception::SQL;
use Text::Wrap ();

@Enigo::Common::Exception::SQL::FailedGetDBH::ISA =
  qw(Enigo::Common::Exception::SQL);
$Enigo::Common::Exception::SQL::FailedGetDBH::VERSION =
  '$Revision: 1.1.1.1 $ ' =~ /\$Revision:\s+([^\s]+)/;


######################################################################
##### Constructor: new
######################################################################

=pod

=head2 CONSTRUCTOR_NAME: new

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 22 JUN 2000>

=head2 PURPOSE:

To create and return a hash reference blessed into
Enigo::Common::Exception::SQL::FailedGetDBH.

=head2 ARGUMENTS:

none

=head2 RETURNS:

An object blessed into Enigo::Common::Exception::SQL::FailedGetDBH.

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

    local $^W = 0;
    return(bless Enigo::Common::Exception->new
           ({TEXT => Text::Wrap::wrap('','    ',"SQLError: FailedGetDBH: Failed to secure a database handle in Enigo::Common::SQL::SQL::get_dbh\n<ERROR_LOCATION/>"),
             VALUE => 1}),
           $self);
  }

1;
