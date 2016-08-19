#!/usr/bin/perl -wc
# 
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: fork.pm

=head1 Enigo::Common::Override::PerlExceptions::fork;

I<REVISION: 1.1.2.2>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: 23:05 31 OCT 2000>

=head1 PURPOSE:

This package provides a version of fork that throws exceptions on failure.

=head1 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

package Enigo::Common::Override::PerlExceptions::fork;

use Enigo::Common::Exception;
require Enigo::Common::Exception::Perl::fork;

sub fork
  {
    my $pid = eval {fork};

    if ($@ ne '')
      {
    throw Enigo::Common::Exception::Perl::fork();
      }
    elsif ($pid)
      {
    return $pid;
      }
    else
      {
    return 0;
      }
  }
