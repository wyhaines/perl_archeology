#!/usr/bin/perl
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: initialize.pm

=head1

I<REVISION: .1>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: 11 Jan 2001>

=head1 PURPOSE:

Provides a source filter that takes constructs in the form of

  initialize($data);

and replaces them with Perl code like:

  my $self = shift;
  my ($data) = @_;

This will typically be used at the head of an ETL task to do the
common, basic setup tasks.

=head1 EXAMPLE:

=head1 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

package Enigo::Common::Filter::Quetl::initialize;

$Enigo::Common::Filter::Quetl::initialize::VERSION = '.1';

sub filter {
  my $self = shift;
  my $code = shift;

  if ($code =~ /initialize\s*(.*?)\s*;/) {
    my $assignee = $1;
    $assignee =~ s/^\s*\(//;
    $assignee =~ s/\)\s*$//;
    my $expansion = <<ECODE;
my \$self = shift;
my ($assignee) = \@_;
ECODE
    $code =~ s/initialize\s*.*?\s*;/$expansion/g;
  }

  return $code;
}

1;
