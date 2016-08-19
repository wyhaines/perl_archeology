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

Overrides Log::Dispatch::Screen to get it to inherit from our
overriding parents.

=head1 EXAMPLE:

=head1 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

package Enigo::Common::Log::Dispatch::Screen;

use strict;
use vars qw(@ISA $VERSION);

use base qw(Enigo::Common::Log::Dispatch::Output);
require Log::Dispatch::Screen;
push @ISA,'Log::Dispatch::Screen';

use fields qw(stderr);

($VERSION) =
  '$Revision: 1.1.1.1 $' =~ /\$Revision:\s+([^\s]+)/; #';

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
  $self->{stderr} = $params{stderr} if $params{stderr};

  return $self;
}

sub log_message {
  my Enigo::Common::Log::Dispatch::Screen $self = shift;
  $self->SUPER::log_message(@_);
}

1;
