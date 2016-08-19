#!/usr/bin/perl -wc
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: Filter.pm

=head1

I<REVISION: $Revision: 1.1.1.1 $>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: $Date: 2001/12/17 02:28:37 $>

=head1 PURPOSE:

Provides a mechanism to filter a body of code before it is
evaled.  This allows for the creation of new syntax conventions
or shortcuts.  The intent is to be able to add to the normal Perl
vernacular pseudocode type constructs which will get extrapolated
into actual Perl code.  Good for using Perl as an embedded
language where there are some common types of constructs which
will be used frequently.

=head1 EXAMPLE:

  use Enigo::Common::Filter qw(Quetl);

  use Enigo::Common::Filter qw(misc RPCServer);

=head1 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

package Enigo::Common::Filter;

use strict;
use Enigo::Common::Exception qw(:IO);

$Enigo::Common::Filter::VERSION = '.2';


######################################################################
##### Method: import
######################################################################

=pod

=head2 METHOD_NAME: import

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 11 Jan 2001>
 
=head2 PURPOSE:

Determine which set or sets of filters to utilize.

=head2 ARGUMENTS:

Takes a list of labels, which will be mapped as:

  Enigo::Common::Filter::<LABEL>::catalog.pl

The catalog.pl pointed to by that mapping will be read and used
to identify the specific filters that will then be read and
prepared for use.

=head2 THROWS:

  Enigo::Common::Exception::IO::File::NotFound
  Enigo::Common::Exception::IO::File::NotReadable

=head2 RETURNS:

undef

=head2 EXAMPLE:

  use Enigo::Common::Filter qw(RPCServer misc);

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub import {
  my $package = shift;

  %Enigo::Common::Filter::list = {}
    unless defined %Enigo::Common::Filter::list;
  foreach my $catalog (@_) {
    my $catalog_file = "Enigo/Common/Filter/$catalog/catalog.pl";

    foreach my $directory (@INC) {
      next unless -r "$directory/$catalog_file";

      my $code;
      my $catalog_code;
      {
    local $/;
    open(INC,"<$directory/$catalog_file") or
      throw Enigo::Common::Exception::IO::File::NotReadable("$directory/$catalog_file");
    $code = <INC>;
    close INC;
      }

      my @filters = eval($code);
      #put a throw in here if $@

      foreach my $filter (@filters) {
    my $filter_file = $filter;
    $filter_file =~ s|::|/|g;
    $filter_file .= '.pm';
    require $filter_file;
    no strict 'refs';
    push(@{$Enigo::Common::Filter::list{caller()}},
         [\&{"${filter}::filter"},
          $filter]);
    use strict 'refs';
      }
    }
  }
}



######################################################################
##### Method: filter
######################################################################

=pod

=head2 METHOD_NAME: filter

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 11 Jan 2001>

=head2 PURPOSE:

Runs all of the defined filters over the supplied scalar.

=head2 ARGUMENTS:

Takes a single scalar as an argument.  The scalar contains the
data that is to be filtered.

=head2 THROWS:

=head2 RETURNS:

The filtered data.

=head2 EXAMPLE:

my $filtered = Enigo::Common::Filter->filter({CODE => $code});

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub filter {
  my $self = shift;
  my $code = shift;

  foreach my $filter (@{$Enigo::Common::Filter::list{caller()}}) {
    no strict 'refs';
    $code = &{$filter->[0]}($filter->[1],$code);
    use strict 'refs';
  }

  return $code;
}

1;
