#!/usr/bin/perl -c
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: $RCSfile: ExecuteFailed.pm,v $

=head1 Enigo::Common::Exception::IO::DB::ExecuteFailed

I<REVISION:$Revision: 1.1.1.1 $>

I<AUTHOR: $Author: khaines $>

I<DATE_MODIFIED: $Date: 2001/12/17 02:28:37 $>

=head1 PURPOSE:

An C<execute()> call on a DBI statement handle failed.  Use this class to
throw the exception.

=head1 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################
package Enigo::Common::Exception::IO::DB::ExecuteFailed;

use strict;

require Enigo::Common::Exception::IO::DB;

@Enigo::Common::Exception::IO::DB::ExecuteFailed::ISA =
  qw(Error Enigo::Common::Exception::IO::DB);
$Enigo::Common::Exception::IO::DB::ExecuteFailed::VERSION = '2000_06_06_15_02';


######################################################################
##### Constructor: new
######################################################################

=pod

=head2 CONSTRUCTOR_NAME: new

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 15 JUN 2000>

=head2 PURPOSE:

To create and to return a hash blessed into
Enigo::Common::Exception::IO::DB::ExecuteFailed.

=head2 ARGUMENTS:

Takes either a list of two scalars (or three), the statement handle,
a reference to the array of bind values used in the C<execute()> call,
and, optionally, a numeric value for the exception, or takes a hash
reference containing STH, PARAMS, and, optionally, VALUE keys describing
the execute attempt criteria.

If VALUE is omitted, it defaults to 1.

=head2 RETURNS:

An hash blessed into Enigo::Common::Exception::IO::DB::ExecuteFailed.

=head2 EXAMPLE:

  eval
    {
      $sth->execute(@params);
    };
  throw Enigo::Common::Exception::IO::DB::ExecuteFailed
    ({STH => $sth,
      PARAMS => @params})
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

    my $param = {STH => '',
                 PARAMS => '',
                 VALUE => 1};

    if (ref($_[0]) eq 'HASH')
      {
        $param->{STH} = $_[0]->{STH};
        $param->{PARAMS} = $_[0]->{PARAMS};
        $param->{VALUE} = exists $_[0]->{VALUE} ? $_[0]->{VALUE} :
                                                  $param->{VALUE};
      }
    else
      {
        $param->{STH} = $_[0];
        $param->{PARAMS} = $_[1];
        $param->{VALUE} = defined $_[2] ? $_[2] : $param->{VALUE};
      }

    my $sql = 'UNKNOWN';
    if ($param->{STH})
      {
    $sql = $param->{STH}->{Statement};
      } 

    my $param_line = undef;
    if ($param->{PARAMS})
      {
        $param_line = join('',
               "\nwith bind parameters of:\n\n" .
               join(', ',
                @{$param->{PARAMS}}),
               "\n\n");
      }

    my $reason_text = $DBI::errstr ? " with error:\n\n$DBI::errstr" : '.';
    my $text = <<ETXT;
Error: ExecuteFailed: execute() on DBI statement handle for SQL statement:

$sql
$param_line
failed$reason_text

<ERROR_LOCATION/>
ETXT

    return bless Enigo::Common::Exception->new({TEXT => $text,
                         VALUE => $param->{VALUE}}),
           $self;
  }


1;
