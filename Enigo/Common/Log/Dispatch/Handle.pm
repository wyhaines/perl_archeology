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

Overrides Log::Dispatch::Handle to get it to inherit from our
overriding parents.

=head1 EXAMPLE:

=head1 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################
package Enigo::Common::Log::Dispatch::Handle;

use strict;
use vars qw(@ISA $VERSION);
use Log::Dispatch::Output;

use base qw(Enigo::Common::Log::Dispatch::Output);
require Log::Dispatch::Handle;
push @ISA,'Log::Dispatch::Handle';

use fields qw(handle);

($VERSION) =
  '$Revision: 1.1.1.1 $' =~ /\$Revision:\s+([^\s]+)/; #';

sub new
{
    my $proto = shift;
    my $class = ref $proto || $proto;

    my %params = @_;

    my $self;
    {
    no strict 'refs';
    $self = bless [ \%{"${class}::FIELDS"} ], $class;
    }

    $self->_basic_init(%params);
    $self->{handle} = $params{handle};

    return $self;
}

sub log_message
{
    my Enigo::Common::Log::Dispatch::Handle $self = shift;
    $self->SUPER::log_message(@_);
}

1;
