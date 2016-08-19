#!/usr/bin/perl -wc
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: Output.pm

=head1

I<REVISION: $Revision: 1.1.1.1 $>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: 27 Sept 2001>

=head1 PURPOSE:

This is an abstract class that provides a lot of common pieces
parts for writing different output destinations for
Enigo::Common::Log::Dispatch.  It is basically just a wrapper
around Log::Dispatch::Output.

=head1 EXAMPLE:

=head1 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

package Enigo::Common::Log::Dispatch::Output;

use strict;

use base qw(Enigo::Common::Log::Dispatch::Base Log::Dispatch::Output);

use vars qw($VERSION);

use Carp ();

use Enigo::Common::Exception qw(:IO);
require Enigo::Common::Log::Dispatch::Output::Exception::NoName;
require Enigo::Common::Log::Dispatch::Output::Exception::NoMinLevel;
require Enigo::Common::Log::Dispatch::Output::Exception::InvalidLevel;
require Enigo::Common::Log::Dispatch::Output::Exception::MinGreaterThanMax;

($VERSION) = '$Revision: 1.1.1.1 $' =~ /\$Revision:\s+([^\s]+)/; #';

sub new
  {
    my $proto = shift;
    my $class = ref $proto || $proto;
    $class->SUPER::new(@_);
  }

sub log
  {
    my $self = shift;
    my %params = @_;

    $self->SUPER::log(@_);
  }

sub _basic_init
  {
    my Enigo::Common::Log::Dispatch::Output $self = shift;
    my %params = @_;

    # Map the names to numbers so they can be compared.
    $self->{level_names} = [$self->levels()];

    my $x = 0;
    $self->{level_numbers} = {map { lc($_) => $x++ } @{ $self->{level_names} } };

    $self->{name} = $params{name} or
      throw Enigo::Common::Log::Dispatch::Output::Exception::NoName($self);

    exists $params{min_level} or
      throw Enigo::Common::Log::Dispatch::Output::Exception::NoMinLevel($self);

    $self->{min_level} = $self->_level_as_number($params{min_level});

    # Either use the parameter supplies or just the highest possible
    # level.throw Enigo::Common::Log::Dispatch::Output::Exception::
    $self->{max_level} =
      exists $params{max_level} ?
    $self->_level_as_number($params{max_level}) :
    $#{$self->{level_names}};

    $self->{min_level} <= $self->{max_level} or
      throw Enigo::Common::Log::Dispatch::Output::Exception::MinGreaterThanMax
    ({MIN => $self->{min_level},
      MAX => $self->{max_level}});

    my @cb = $self->_get_callbacks(%params);
    $self->{callbacks} = \@cb if @cb;
  }

sub name
  {
    my Enigo::Common::Log::Dispatch::Output $self = shift;

    $self->SUPER::name(@_);
  }

sub min_level
  {
    my Enigo::Common::Log::Dispatch::Output $self = shift;

    $self->SUPER::min_level(@_);
  }

sub max_level
  {
    my Enigo::Common::Log::Dispatch::Output $self = shift;

    $self->SUPER::max_level(@_);
  }

sub accepted_levels
  {
    my Enigo::Common::Log::Dispatch::Output $self = shift;

    $self->SUPER::accepted_levels(@_);
  }

sub _should_log
  {
    my Enigo::Common::Log::Dispatch::Output $self = shift;

    $self->SUPER::_should_log(@_);
  }

sub _level_as_number
  {
    my Enigo::Common::Log::Dispatch::Output $self = shift;
    my $level = shift;

    defined $level or
      throw
    Enigo::Common::Log::Dispatch::Output::Exception::InvalidLevel('undef');

    if ($level =~ /^\d$/) {
      throw Enigo::Common::Log::Dispatch::Output::Exception::InvalidLevel($level)
    if ($level < 0 or
        $level >= scalar($self->levels()));

      return $level;
    }

    $self->level_is_valid($level) or
      throw
    Enigo::Common::Log::Dispatch::Output::Exception::InvalidLevel($level);

    return $self->{level_numbers}{lc($level)};
  }

1;
