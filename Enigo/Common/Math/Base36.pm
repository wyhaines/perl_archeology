#!/usr/bin/perl -wc
#
######################################################################
##### Header
######################################################################

=pod

=head1 NAME: $RCSfile: Base36.pm,v $

Z<>

I<REVISION: $Revision: 1.1 $>

I<AUTHOR: >

I<DATE_MODIFIED: $Date: 2001/12/17 06:41:38 $>

=head1 PURPOSE:

Provides a routine to convert number to and from base 36.
Why?  Well, it provides a compact way to encode large numbers,
especially if they are being used within URLs or the like.

=head1 EXAMPLES:

  No examples currently.

Z<>

=head1 TODO:

Z<>

Z<>

Z<>

=head1 DESCRIPTION:

=cut

######################################################################
######################################################################

package Enigo::Common::Math::Base36;

use strict;
use vars qw($VERSION @ISA @EXPORT_OK @EXPORT $base26_digits);

use Carp;
use Exporter;
use Math::BigInt qw(:constant);

@ISA = qw(Math::BigInt Exporter);

@EXPORT = qw();
@EXPORT_OK = qw(from_base36 to_base36);

($VERSION) =
  '$Revision: 1.1 $' =~ /\$Revision:\s+([^\s]+)/;#';


$Enigo::Common::Math::Base36::base36_digits =
  join('', 
       '0' .. '9', 
       'A' .. 'Z');

use constant B36_BASE => 36;

sub from_base36
{
    my $num = shift;
    my @digits = split(//, $num);
    my $answer = new Math::BigInt "0";
    my $n;
    my $d;
    while (defined($d = shift @digits)) {
    $answer = $answer * B36_BASE;
    $n = index($base36_digits, $d);
    if ($n < 0) {
        croak __PACKAGE__ . "::from_base36 -- invalid base 36 digit $d";
    }
    $answer = $answer + $n;
    }
    return $answer;
}

sub to_base36
{
    my $num = shift;
    my @digits;
    my $q;
    my $r;
    my $d;
    while ($num > 0) {
    $q = $num / B36_BASE;
    $r = $num % B36_BASE;
    $d = substr($base36_digits, $r, 1);
    unshift @digits, $d;
    $num = $q;
    }
    return join('', @digits);
}

1;
