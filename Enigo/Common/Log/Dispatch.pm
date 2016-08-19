#!/usr/bin/perl -wc
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: Dispatch.pm

=head1

I<REVISION: $Revision: 1.1.1.1 $>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: 26 Sept 2001>

=head1 PURPOSE:

This is a superclass of Log::Dispatch that changes the logging levels
to more standard Enigo levels.  It also makes it possible to change
the supported logging levels easily in the future, should the need
for other levels develop.

=head1 EXAMPLE:

=head1 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

package Enigo::Common::Log::Dispatch;

use strict;

use vars qw[$VERSION %LEVELS];

use base qw(Enigo::Common::Log::Dispatch::Base Log::Dispatch);

use Carp ();

($VERSION) = '$Revision: 1.1.1.1 $' =~ /\$Revision:\s+([^\s]+)/; #'

BEGIN {
  no strict 'refs';

  #####
  #Remove any methods dynamically defined in Log::Dispatch
  #####
  foreach my $level
    (Enigo::Common::Log::Dispatch::Base::log_dispatch_levels()) {
      undef *{$level};
    }

  #####
  #Dynamically define our own logging level named methods.
  #####
  foreach my $level
    (Enigo::Common::Log::Dispatch::Base::levels()) {
      *{$level} = sub {
    my Enigo::Common::Log::Dispatch $self = shift;
    $self->log(level => $level, message => "@_");
      };
      $LEVELS{$level} = 1;
    }

  #####
  #Go through the list of Log::Dispatch logging levels, and
  #dynamically setup methods for any of them that are different
  #from our Enigo logging levels so that they will log an
  #equivalent Enigo level message.
  #####
  foreach my $level
    (Enigo::Common::Log::Dispatch::Base::log_dispatch_levels()) {
      my $mapped_level = Enigo::Common::Log::Dispatch::Base->map_level($level);
      next unless $level ne $mapped_level;

    *{$level} = sub {
      my Enigo::Common::Log::Dispatch $self = shift;
      $self->log(level => $mapped_level, message => "@_");
    };
  }
}


######################################################################
##### Constructor: new
######################################################################

=pod

=head2 CONSTRUCTOR_NAME: new

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 26 Setp 2001>

=head2 PURPOSE:

Returns a blessed pseudo-hash.  This does not do anything special
besides call the superclass.

=head2 ARGUMENTS:

=head2 THROWS:

=head2 RETURNS:

=head2 EXAMPLE:

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub new {
  my $proto = shift;
  my $class = ref $proto || $proto;
  my $self = $class->SUPER::new(@_);

  return $self;
}

1;
