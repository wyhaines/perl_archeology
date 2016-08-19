#!/usr/bin/perl -wc
#
######################################################################
##### Header
######################################################################

=pod

=head1 NAME: $RCSfile: MkDirs.pm,v $

Z<>

I<REVISION: $Revision: 1.1.1.1 $>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: $Date: 2001/12/17 02:28:37 $>

=head1 PURPOSE:

MkDirs will create all of the non-existing parent directories that
make up the path passed into it.  It assumes that it is being given
a full path to a file, so it does not create a directory corresponding
to the last element within the path.

=head1 EXAMPLES:

  mkdirs('/tmp/foo/bar/blither.txt');

This will create all of the dirs comprising '/tmp/foo/bar'.

Z<>

=head1 TODO:

Z<>

Z<>

Z<>

=head1 DESCRIPTION:

=cut

######################################################################
######################################################################

package Enigo::Common::IO::MkDirs;

use strict;
use vars qw($VERSION @ISA @EXPORT_OK);

use Enigo::Common::ParamCheck qw(paramCheck);

use Exporter;

@ISA = qw(Exporter);

@EXPORT_OK = qw(mkdirs);

($VERSION) =
  '$Revision: 1.1.1.1 $' =~ /\$Revision:\s+([^\s]+)/;#';

sub mkdirs {
  my ($param) = paramCheck([PATH => 'U'],@_);
  my ($wholedir) = $param->{PATH} =~ m{^(.*?)/[^/]+$};
  my $stepdir;

  while ($wholedir !~ /^\s*$/) {
    $wholedir =~ s{^(/?[^/]*/?)}{};
    $stepdir .= $1;
    mkdir $stepdir,0775 unless (-e $stepdir);
  }
}

1;
