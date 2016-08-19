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

Provides a new Dispatcher, Callback.  Callback allows one to give
Log::Dispatch a code ref to be invoked as a logging destination.

=head1 EXAMPLE:

  $dispatcher->add
    (Enigo::Common::Log::Dispatcher::Callback->new
      (callback => \&log_to_db));

=head1 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

package Enigo::Common::Log::Dispatch::Callback;

use strict;
use vars qw(@ISA $VERSION);

use base qw(Enigo::Common::Log::Dispatch::Output);

use fields qw(callback);

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
  #####
  #If callback is defined, goodie.  If not, set it to an
  #anonymous sub that simply returns a true value.
  #####
  $self->{callback} = $params{callback} ?
    $params{callback} : sub {return 1};

  return $self;
}

sub log_message {
  my Enigo::Common::Log::Dispatch::Callback $self = shift;

  &{$self->{callback}}(@_);
}

1;
