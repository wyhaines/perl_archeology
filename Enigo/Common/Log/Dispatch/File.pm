#!/usr/bin/perl -wc
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: $RCSFile$

=head1

I<REVISION: $Revision: 1.1.1.1 $>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: $Date: 2001/12/17 02:28:37 $>

=head1 PURPOSE:

Overrides Log::Dispatch::File to get it to inherit from our
overriding parents.

=head1 EXAMPLE:

=head1 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################
package Enigo::Common::Log::Dispatch::File;

use strict;
use vars qw(@ISA $VERSION);

use base qw(Enigo::Common::Log::Dispatch::Output);
require Log::Dispatch::File;
push @ISA,'Log::Dispatch::File';

use fields qw(fh filename);

use Enigo::Common::Exception qw(:IO);

($VERSION) =
  '$Revision: 1.1.1.1 $' =~ /\$Revision:\s+([^\s]+)/; #';

use IO::File;

#####
# Prevents death later on if IO::File can't export this constant.
#####
BEGIN {
  my $exists;
  eval { $exists = O_APPEND(); };

  *O_APPEND = \&APPEND unless defined $exists;
}

sub APPEND {;};

sub new {
  my $proto = shift;
  my $class = ref $proto || $proto;

  my %params = @_;

  my $self;
  {
    no strict 'refs';
    $self = bless [ \%{"${class}::FIELDS"} ], $class;
  }

  $self->_basic_init(%params);
  $self->_make_handle(%params);

  return $self;
}

sub _make_handle {
  my Enigo::Common::Log::Dispatch::File $self = shift;
  my %params = @_;

  $self->{filename} = $params{filename};

  my $mode;
  if ( exists $params{mode}
       &&
       ( $params{mode} =~ /^>>$|^append$|/
     ||
     $params{mode} == O_APPEND())) {
    $mode = '>>';
  } else {
    $mode = '>';
  }

  $self->{fh} = IO::File->new("$mode$self->{filename}") or
    throw Enigo::Common::Exception::IO::File::NotWriteable($self->{filename});

  $self->{fh}->autoflush(1);
}

sub log_message {
  my Enigo::Common::Log::Dispatch::File $self = shift;
  $self->SUPER::log_message(@_);
}

1;
