#!/usr/bin/perl -w
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: $RCSfile: BadScalarQuery.pm,v $

=head1 Enigo::Common::Exception::SQL::BadScalarQuery

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
package Enigo::Common::Exception::SQL::BadScalarQuery;

use strict;

require Error;
require Enigo::Common::Exception::SQL;
use Text::Wrap ();

@Enigo::Common::Exception::SQL::BadScalarQuery::ISA =
  qw(Enigo::Common::Exception::SQL);
$Enigo::Common::Exception::SQL::BadScalarQuery::VERSION =
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
Enigo::Common::Exception::SQL::BadScalarQuery.  Using 
Enigo::Common::SQL::SQL, a scalar query is one that should return only
a single column of a single row.  This exception is thrown
if a query returns more than one row or one column.

=head2 ARGUMENTS:

Takes two, or optionally, three scalar arguments.  The first is the
type of bad scalar query.  Currently defined types are 'row' and
'column'.  The second is the SQL of the offending query.  The last,
optional argument is the exit value of the exception.  This defaults
to 1 if not specified.

The arguments can also be passed via a hash reference with keys of
TYPE, SQL, and VALUE.

=head2 RETURNS:

An object blessed into Enigo::Common::Exception::SQL::BadScalarQuery.

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

    my $param = {TYPE => '',
                 SQL => '',
                 VALUE => 1};

    if (ref($_[0]) eq 'HASH')
      {
        $param->{TYPE} = $_[0]->{TYPE};
        $param->{SQL} = $_[0]->{SQL};
        $param->{VALUE} = exists $_[0]->{VALUE} ? $_[0]->{VALUE} :
                                                  $param->{VALUE};
      }
    else
      {
        $param->{TYPE} = $_[0];
        $param->{SQL} = $_[1];
        $param->{VALUE} = defined $_[2] ? $_[2] :  $param->{VALUE};
      }

    local $^W = 0;
    $param->{SQL} = Text::Wrap::wrap('','    ',$param->{SQL});
    $^W = 1;

    my $text;
    if ($param->{TYPE} =~ /^\s*r/i)
      {
        $text = <<ETXT;
didn't return exactly one row in scalar query.

SQL:

$param->{SQL}

<ERROR_LOCATION/>
ETXT
      }
    elsif ($param->{TYPE} =~ /^\s*c/i)
      {
        $text = <<ETXT;
didn't return exactly one column in scalar query.

SQL:

$param->{SQL}

<ERROR_LOCATION/>
ETXT
      }
    else
      {
        $text = <<ETXT;
undefined problem in scalar query.

SQL:

$param->{SQL}

<ERROR_LOCATION/>
ETXT
      }

    return(bless Enigo::Common::Exception->new
           ({TEXT => "SQLError: BadScalarQuery: $text",
             VALUE => $param->{VALUE}}),
           $self);

  }

1;
