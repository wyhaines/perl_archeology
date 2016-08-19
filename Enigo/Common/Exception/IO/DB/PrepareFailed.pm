#!/usr/bin/perl -c
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: $RCSfile: PrepareFailed.pm,v $

=head1 Enigo::Common::Exception::IO::DB::PrepareFailed

I<REVISION:$Revision: 1.1.1.1 $>

I<AUTHOR: $Author: khaines $>

I<DATE_MODIFIED: $Date: 2001/12/17 02:28:37 $>

=head1 PURPOSE:

A prepare call on a database handle failed.  Use this class to throw the
exception.

=head1 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################
package Enigo::Common::Exception::IO::DB::PrepareFailed;

use strict;

require Text::Wrap;
require Enigo::Common::Exception::IO::DB;

@Enigo::Common::Exception::IO::DB::PrepareFailed::ISA =
  qw(Error Enigo::Common::Exception::IO::DB);
$Enigo::Common::Exception::IO::DB::PrepareFailed::VERSION = '2000_06_06_15_02';


######################################################################
##### Constructor: new
######################################################################

=pod

=head2 CONSTRUCTOR_NAME: new

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 15 JUN 2000>

=head2 PURPOSE:

To create and to return an object blessed into
Enigo::Common::Exception::IO::DB::PrepareFailed.

=head2 ARGUMENTS:

Takes either a list of two scalars (or three), the database handle, the SQL
that the prepare was attempted for, and optionally a numeric value for the
exception, or takes a hash reference containing DBH, SQL, and, optionally,
VALUE keys describing the prepare attempt criteria.

If VALUE is omitted, it defaults to 1.

=head2 RETURNS:

An hash blessed into Enigo::Common::Exception::IO::DB::PrepareFailed.

=head2 EXAMPLE:

  my $sql = 'select foo from bar';
  my $sth;
  eval
    {
      $sth = $dbh->prepare($sql);
    };
  throw Enigo::Common::Exception::IO::DB::PrepareFailed
    ({DBH => $dbh,
      SQL => $sql})
    if $@;

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

    my $param = {DBH => '',
                 SQL => '',
                 VALUE => 1};

    if (ref($_[0]) eq 'HASH')
      {
        $param->{DBH} = $_[0]->{DBH};
        $param->{SQL} = $_[0]->{SQL};
        $param->{VALUE} = exists $_[0]->{VALUE} ? $_[0]->{VALUE} :
                                                  $param->{VALUE};
      }
    else
      {
        $param->{DBH} = $_[0];
        $param->{SQL} = $_[1];
        $param->{VALUE} = defined $_[2] ? $_[2] : $param->{VALUE};
      }

    my $database = 'UNKNOWN';
    my $user = 'UNKNOWN';
    my $sql = 'UNKNOWN';
    if ($param->{DBH})
      {
        $database = $param->{DBH}->{Name};
        $user = @{[split(/@/,$param->{DBH}->{USER})]}[0];
      } 
    $sql = ($param->{SQL} || $sql);

    my $reason_text = $DBI::errstr ? " with error:\n\n$DBI::errstr" : '.';
    my $text = <<ETXT;
Error: PrepareFailed: prepare() on DBI database handle to '$database' database as '$user' user for SQL statement:

$sql

failed$reason_text

<ERROR_LOCATION/>
ETXT
    local $^W;
    $text = Text::Wrap::wrap(undef,undef,$text);

    return bless Enigo::Common::Exception->new({TEXT => $text,
                         VALUE => $param->{VALUE}}),
           $self;
  }


1;
