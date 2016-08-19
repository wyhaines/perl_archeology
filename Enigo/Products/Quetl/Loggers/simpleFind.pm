#!perl
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: simpleFind.pm

=head1

I<REVISION: 1>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: 21 Mar 2001>

=head1 PURPOSE:

Implements a simple file find functionality.  Takes a hash reference
with keys of PATH and MASK, and returns an array containing all
of the paths at or under the one given which are not directory paths,
and are not dead links.

PATH will accept either a simple scalar value specifying the path
to look in, or an array reference of paths, all of which will
be explored.

=head1 EXAMPLE:

=head1 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

use strict;
use File::Find;
use Enigo::Common::ParamCheck qw(paramCheck);

sub simpleFind {
  my ($param) = paramCheck([PATH => 'U',
                MASK => 'U'],@_);

  use vars qw($mask);
  local $mask = $param->{MASK};

  unless (ref($param->{PATH}) eq 'ARRAY') {
    $param->{PATH} = [$param->{PATH}];
  }

  use vars qw(@simplefind_files);
  local @simplefind_files;

  find(\&wanted,@{$param->{PATH}});

  sub wanted {
    push(@simplefind_files,$File::Find::name)
      if ($File::Find::name =~ m{$mask} and
      ((! -d $File::Find::name) or
       (-l $File::Find::name and
        -e $File::Find::name)));
  }

  return @simplefind_files;
}
1;
