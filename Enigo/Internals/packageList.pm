#!/usr/bin/perl -wc
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: $RCSfile: packageList.pm,v $

=head1

I<REVISION: $Revision: 1.1.1.1 $>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: $Date: 2001/12/17 02:28:37 $>

=head1 PURPOSE:

Takes a file name or a Perl package name and returns a list of all of
the packages 'use'd or 'require'd in that code, or in any code that it
uses or requires.

=head1 EXAMPLE:

  Enigo::Internals::packageList::list($ARGV[0]);

=head1 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

package Enigo::Internals::packageList;

use strict;
use IO::File;

use Enigo::Common::ParamCheck qw(paramCheck);

$Enigo::Internals::packageList::VERSION = ('$Revision: 1.1.1.1 $' =~ m{:\s+([\d\.]+)});#'


######################################################################
##### Method: list()
######################################################################

=pod

=head2 METHOD_NAME: list

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 15 Aug 2001>

=head2 PURPOSE:

This method takes as an argument the path to a file or the name
of a Perl package, and returns a list of all of the packages
'use'd or 'require'd within that package, and all of the packages
'use'd or 'require'd within those packages, and so on.

As these files are being traversed, the module also takes into
account any 'use lib' or 'use Enigo::lib' statements that it
encounters.

=head2 ARGUMENTS:

Takes a single argument, the path of the file or the name of
the package.  If the argument matches an existing file, it is
assumed to refer to that file, else it is assumed to be a
package name, and @INC will be searched for the file.

The argument can also be passed via a hash ref, with a key name
of TARGET.

=head2 THROWS:

=head2 RETURNS:

A list of package names.

=head2 EXAMPLE:

  require Enigo::Internals::packageList;
  @packages = Enigo::Internals::packageList::list
	        ("Enigo::Internals::packageList");


=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub list {
  %Enigo::Internals::packageList::files = ();

  _real_list(@_);
}

sub _real_list {
  my ($param) = paramCheck([TARGET => 'U'],@_);

  my $filename;
  my %packages;

  if (-e $param->{TARGET}) {
    $filename = $param->{TARGET};
    $packages{$param->{TARGET}}++;
  } else {
    my $partial_path = $param->{TARGET};
    $partial_path =~ s{::}{/}g;
    $partial_path = "$partial_path.pm";

    foreach my $inc_path (@INC) {
      $inc_path = "$inc_path/" unless $inc_path =~ /\/$/;
      my $path = $inc_path . $partial_path;
      if (-e $path) {
	$filename = $path;
	$packages{$param->{TARGET}}++;
	last;
      }
    }
  }

  if ($filename and !$Enigo::Internals::packageList::files{$filename}) {
    $Enigo::Internals::packageList::files{$filename}++;
    my $fh = IO::File->new($filename,'r');
    if ($fh) {
      while (my $line = $fh->getline) {
	if ($line =~ m{(?:use\s+lib|use\s+Enigo::lib)}) {
	  eval $line;
	}
	#Yuck.  There has to be a more reliable way.
	if ($line =~ m{(?:^|;)\s*(?:use|require|do)\s+([^\s;]+)}) {
	  my $thingy = $1;
	  map {$packages{$_}++} _real_list({TARGET => $thingy});
	}
      }
      $fh->close();
    }
  }

  return keys(%packages);
	
}



1;
