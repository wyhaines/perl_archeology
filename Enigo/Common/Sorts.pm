#!/usr/bin/perl -c
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: $RCSfile: Sorts.pm,v $

=head1 Enigo::Common::Sorts

I<REVISION:$Revision: 1.1.1.1 $>

I<AUTHOR: $Author: khaines $>

I<DATE_MODIFIED: $Date: 2001/12/17 02:28:37 $>

=head1 PURPOSE:

This package contains a collection of general purpose
sort routines.  Those that start with I<sort> are intented to be
called standalone.  The others are intended to be invoked as a
subroutine argument to the C<sort> command.

=head1 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

package Enigo::Common::Sorts;

use strict;
use vars qw($VERSION @ISA @EXPORT_OK);
require Exporter;

@ISA = qw(Exporter);
@EXPORT_OK = qw(sortHashByStringValue
        sortHashByNumericValue
        sortHashByHRStringValue);
($VERSION) =
  '$Revision: 1.1.1.1 $' =~ /\$Revision:\s+([^\s]+)/;#';

######################################################################
##### Subroutine: sortHashByStringValue
######################################################################

=pod

=head2 SUBROUTINE_NAME: sortHashByStringValue

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 2000 May 31>

=head2 PURPOSE:

Take a HASHREF and sort the HASH by its values,
returning an ARRAY containing the HASH keys, sorted
in string order by the values that they point to.

=head2 ARGUMENTS:

Takes a single HASH reference.

=head2 RETURNS: 

An ARRAY containing the HASH keys in string sorted order.

=head2 EXAMPLE:

@sorted_hash_keys = %{sortHashByStringValue(\$hash)};

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub sortHashByStringValue
  {
    my $hashref = shift;
    my @keylist = keys(%{$hashref});
    return sort
      {
    $hashref->{$a} cmp $hashref->{$b};
      } @keylist;
  }



######################################################################
##### Subroutine: sortHashByNumericValue
######################################################################

=pod

=head2 SUBROUTINE_NAME: sortHashByNumericValue

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 2000 May 31>

=head2 PURPOSE:

Take a HASHREF and sort the HASH by its values,
returning an ARRAY containing the HASH keys, sorted
in numeric order by the values that they point to.

=head2 ARGUMENTS:

Takes a single HASH reference.

=head2 RETURNS: 

An ARRAY containing the HASH keys in string sorted order.

=head2 EXAMPLE:

%sorted_hash = %{sortHashByNumericValue(\$hash)};

=head2 TODO:


Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub sortHashByNumericValue
  {
    my $hashref = shift;
    my @keylist = keys(%{$hashref});
    return sort
      {
    $hashref->{$a} <=> $hashref->{$b};
      } @keylist;
  }


######################################################################
##### Subroutine: sortHashByHRStringValue
######################################################################

=pod

=head2 SUBROUTINE_NAME: sortHashByHRStringValue

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 8 Nov 2001>

=head2 PURPOSE:

Takes a hashref pointing to a hash, the values of which are
themselves hashrefs.  It will sort the main hash according to
the sort order of some specified element in all of the value
hashrefs.  It returns an array containing the hash keys in sorted
order.

=head2 ARGUMENTS:

Takes a hashref pointing to the hash to sort, and a scalar containing
the key to use to sort on.

=Head2 RETURNS:

An ARRAY containing the HASH keys in string sorted order.

=head2 EXAMPLE:

@sorted_hash_keys = %{sortHashByStringValue(\$hash,'NAME')};

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub sortHashByHRStringValue
  {
    my $hashref = shift;
    my $sortkey = shift;
    my @keylist = keys(%{$hashref});
    return sort
      {
    $hashref->{$a}->{$sortkey} cmp $hashref->{$b}->{$sortkey};
      } @keylist;
  }


######################################################################
##### Subroutine: sortHashByHRNumericValue
######################################################################

=pod

=head2 SUBROUTINE_NAME: sortHashByHRNumericValue

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 8 Nov 2001>

=head2 PURPOSE:

Takes a hashref pointing to a hash, the values of which are
themselves hashrefs.  It will sort the main hash according to
the sort order of some specified element in all of the value
hashrefs.  It returns an array containing the hash keys in sorted
order.

=head2 ARGUMENTS:

Takes a hashref pointing to the hash to sort, and a scalar containing
the key to use to sort on.

=Head2 RETURNS:

An ARRAY containing the HASH keys in string sorted order.

=head2 EXAMPLE:

@sorted_hash_keys = %{sortHashByNumericValue(\$hash,'WEIGHT')};

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub sortHashByHRNumericValue
  {
    my $hashref = shift;
    my $sortkey = shift;
    my @keylist = keys(%{$hashref});
    return sort
      {
    $hashref->{$a}->{$sortkey} <=> $hashref->{$b}->{$sortkey};
      } @keylist;
  }



1;

