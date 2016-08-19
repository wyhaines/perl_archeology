#!/usr/bin/perl -wc
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: $RCSfile: MethodHash.pm,v $

=head1

I<REVISION: $Revision: 1.1.1.1 $>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: $Date: 2001/12/17 02:28:37 $>

=head1 PURPOSE:

Provides an blessed hash object that provides an interface for
accessing hash elements via method call syntax.  The point of
this is to allow a streamlined syntax for doing multiple
assignments to a hash, such as a hash containing configuration
information, without a lot of clutter.

=head1 EXAMPLE:

  $self->{CONFIG} = Enigo::Common::MethodHash->new();
  $self->{CONFIG}->foo('biz')
                 ->bar({a => 1, b => 2, c => 3}),
                 ->baf(17,23,191);
  print "$self->{CONFIG}->{foo}\n";

This will create a MethodHash object, and then assign values to
three keys, foo, bar, and baf.  These values will be a scalar
value, a hash reference, and an array reference, respectively.
The rule is that a single data item will be set as a scalar
value, but multiple data items will be set as an array reference.
The keys are accessible either through the method interface or
via the normal hash interface.

  @ISA = qw(Enigo::Common::MethodHash);
  sub new {
    my ($proto) = shift;
    my ($class) = ref($proto) || $proto;
    my $self  = Enigo::Common::MethodHash->new();
    bless ($self, $class);
    return $self;
  }

This example shows how to use MethodClass as a superclass in your
own code.  The object so created will be useable as a MethodClass.

=head1 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

package Enigo::Common::MethodHash;

use strict;
use vars qw($AUTOLOAD);

($Enigo::Common::MethodHash::VERSION) =
  '$Revision' =~ /\$Revision:\s+([^\s]+)/;


######################################################################
##### Constructor: new
######################################################################

=pod

=head2 CONSTRUCTOR_NAME: new

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 14 Sept 2001>

=head2 PURPOSE:

Create a blessed hash reference.

=head2 ARGUMENTS:

None.

=head2 THROWS:

=head2 RETURNS:

A blessed hash reference.

=head2 EXAMPLE:

  my $mhrf = Enigo::Common::MethodHash->new()
    ->foo('biz')
    ->bar('baf');
  my $mhrf2 = $mhrf->new();

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub new {
  my ($proto) = shift;
  my ($class) = ref($proto) || $proto;
  my $self  = {};
  bless ($self, $class);
  return $self;
}


######################################################################
##### Subroutine: AUTOLOAD
######################################################################

=pod

=head2 SUBROUTINE_NAME: AUTOLOAD

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 14 Sept 2001>

=head2 PURPOSE:

Intercepts unattached method calls and applies them as calls to
set or get a hash value.

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

sub AUTOLOAD {
  my ($key) = $AUTOLOAD =~ /.*::(.*)/;
  my $self = shift;

  unless (@_) {
    return $self->{$key};
  }

  if (scalar(@_) == 1) {
    $self->{$key} = $_[0];
    return $self;
  } else {
    $self->{$key} = [@_];
    return $self;
  }
}

1;
