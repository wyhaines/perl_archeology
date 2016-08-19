#!/usr/bin/perl -w
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: $RCSfile: FailedSQLStatement.pm,v $

=head1 Enigo::Common::Exception::SQL::FailedSQLStatement

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
package Enigo::Common::Exception::SQL::FailedSQLStatement;

use strict;

require Error;
require Enigo::Common::Exception::SQL;
use Text::Wrap ();

@Enigo::Common::Exception::SQL::FailedSQLStatement::ISA =
  qw(Enigo::Common::Exception::SQL);
$Enigo::Common::Exception::SQL::FailedSQLStatement::VERSION =
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
Enigo::Common::Exception::SQL::FailedSQLStatement.

=head2 ARGUMENTS:

Takes oneo (or two) arguments.  The first is the SQL that that was
to be executed.  The optional second argument is an exit
value for the exception.  This defaults to 1 if not specified.

The arguments may also be passed via a hash reference, with keys of
SQL and VALUE.

=head2 RETURNS:

An object blessed into Enigo::Common::Exception::SQL::FailedSQLStatement.

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

    my $param = {SQL => '',
                 VALUE => 1};

    if (ref($_[0]) eq 'HASH')
      {
        $param->{SQL} = $_[0]->{SQL};
        $param->{VALUE} = exists $_[0]->{VALUE} ? $_[0]->{VALUE} :
                                                  $param->{VALUE};
      }
    else
      {
        $param->{SQL} = $_[0];
        $param->{VALUE} = defined $_[1] ? $_[1] :  $param->{VALUE};
      }


    local $^W = 0;
    my $text;
    if ($param->{SQL})
      {
        $param->{SQL} = Text::Wrap::wrap('','    ',$param->{SQL});
        $text = Text::Wrap::wrap('','    ',<<ETXT);
SQLError: FailedSQLStatement: execution of the following SQL statement failed.

SQL:

$param->{SQL}

<ERROR_LOCATION/>
ETXT
      }
    else
      {
        $text = Text::Wrap::wrap('','    ',<<ETXT);
SQLError: FailedSQLStatement: execution of a SQL statement failed.

<ERROR_LOCATION/>
ETXT
      }
    return(bless Enigo::Common::Exception->new
           ({TEXT => $text,
             VALUE => 1}),
           $self);
  }

1;
