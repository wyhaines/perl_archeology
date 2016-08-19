#!/usr/bin/perl -wc
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: Sequencer.pm

=head1

I<REVISION: $Revision: 1.1.1.1 $>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: $Date: 2001/12/17 02:28:37 $>

=head1 PURPOSE:

This provides a simple sequencer that can be used for very simple
sequencing applications, but is intended mostly as a template to
use to write subclasses with more useful sequencing behavior.
Examples might be a class that maintains sequencing information
within shared memory, or a class that maintains sequencing
information withing a database.

=head1 EXAMPLE:

=head1 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

package Enigo::Common::Sequencer;

use strict;

use Enigo::Common::Exception;
use Enigo::Common::ParamCheck qw(paramCheck);

$Enigo::Common::Sequencer::VERSION = '1.1.2.1';



######################################################################
##### Constructor: new
######################################################################

=pod

=head2 CONSTRUCTOR_NAME: new

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 22 Aug 2000>

=head2 PURPOSE:

Returns a blessed pseudohash as an object of type
Enigo::Common::Seqencer.

=head2 ARGUMENTS:

Takes a hash ref that contains the arguments.  Expects to find
a START key with a value indicating the start point of the
sequence, and an INTERVAL key with a value to be used as
the increment step of the sequence.

=head2 THROWS:

=head2 RETURNS:

A pseudohash blessed to Enigo::Common::Sequencer

=head2 EXAMPLE:

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub new {
  my ($proto) = shift;

  my $self = [{NUMBER => 1, INTERVAL => 2},0,1];

  bless($self,(ref($proto) || $proto));
  $self->_init(@_);

  return $self;
}



######################################################################
##### Method: _init
######################################################################

=pod

=head2 METHOD_NAME: _init

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: >

=head2 PURPOSE:

_init() is a private method that initializes the object after it
has been created.  This method should be subclassed for more
specialized sequencers.

=head2 ARGUMENTS:

Expects to receive a hash reference as described above in the
documentation for new().

=head2 THROWS:

As above for new().

=head2 RETURNS:

undef

=head2 EXAMPLE:

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub _init {
  my ($self) = shift;
  my ($param) = paramCheck([ START => 'NO',
                 INTERVAL => 'NO'],@_);

  $self->setSequenceNumber($param->{START})
    if ($param->{START} ne '');

  $self->setSequenceInterval($param->{INTERVAL})
    if ($param->{INTERVAL} ne '');

  return undef;
}



######################################################################
##### Method:  setSequenceNumber
######################################################################

=pod

=head2 METHOD_NAME: setSequenceNumber

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 22 Aug 2000>

=head2 PURPOSE:

Access routine to set the sequence number to a specific value.

=head2 ARGUMENTS:

Take a single argument, the value to set the sequence number to.
This can also be passed in a hash ref with a key of NUMBER.

=head2 THROWS:

=head2 RETURNS:

undef;

=head2 EXAMPLE:

  $sequence->setSequenceNumber(103718);

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub setSequenceNumber {
  my ($self) = shift;
  my ($param) = paramCheck([NUMBER => 'NO'],@_);

  $self->{NUMBER} = $param->{NUMBER};

  return undef;
}



######################################################################
##### Method:  setSequenceInterval
######################################################################

=pod

=head2 METHOD_NAME: setSequenceInterval

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 22 Aug 2000>

=head2 PURPOSE:

Access routine to set the sequence interval to a specific value.

=head2 ARGUMENTS:

Take a single argument, the value to set the sequence interval to.
This can also be passed in a hash ref with a key of INTERVAL.

=head2 THROWS:

=head2 RETURNS:

undef;

=head2 EXAMPLE:

  $sequence->setIntervalNumber(103718);

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub setSequenceInterval {
    my ($self) = shift;
    my ($param) = paramCheck([INTERVAL => 'N'],@_);

    $self->{INTERVAL} = $param->{INTERVAL};

    return undef;
  }



######################################################################
##### Method:  getCurrentSequenceNumber
######################################################################

=pod

=head2 METHOD_NAME: getCurrentSequenceNumber

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 22 Aug 2000>

=head2 PURPOSE:

Returns the current sequence number.

=head2 ARGUMENTS:

none

=head2 THROWS:

=head2 RETURNS:

undef;

=head2 EXAMPLE:

  my $index = $sequence->getCurrentSequenceNumber();

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub getCurrentSequenceNumber {
  my ($self) = shift;

  return $self->{NUMBER};
}



######################################################################
##### Method:  getNextSequenceNumber
######################################################################

=pod

=head2 METHOD_NAME: getNextSequenceNumber

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 22 Aug 2000>

=head2 PURPOSE:

Returns the next sequence number.  This call adds the sequence
interval to the sequence number and uses the result as the new
current sequence number.

=head2 ARGUMENTS:

none

=head2 THROWS:

=head2 RETURNS:

undef;

=head2 EXAMPLE:

  my $index = $sequence->getNextSequenceNumber();

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub getNextSequenceNumber {
  my ($self) = shift;

  $self->{NUMBER} += $self->{INTERVAL};

  return $self->{NUMBER};
}
1;
