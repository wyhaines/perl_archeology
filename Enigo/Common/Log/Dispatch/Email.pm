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

Subclasses Log::Dispatch::Email to get it to use our subclassed
base and abstract classes.

=head1 EXAMPLE:

=head1 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

package Enigo::Common::Log::Dispatch::Email;

use strict;
use vars qw(@ISA $VERSION);
use base qw(Enigo::Common::Log::Dispatch::Output);
require Log::Dispatch::Email;
push @ISA,'Log::Dispatch::Email';

use fields qw( buffer buffered from subject to );

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

    $self->{subject} = $params{subject} || "$0: log email";
    $self->{to} = ref $params{to} ? $params{to} : [$params{to}]
    or die "No addresses provided to new method for ", ref $self, " object";
    $self->{from} = $params{from};

    #####
    # Default to buffered for obvious reasons!
    #####
    $self->{buffered} = exists $params{buffered} ? $params{buffered} : 1;

    $self->{buffer} = [] if $self->{buffered};

    return $self;
}

sub log_message
{
    my Enigo::Common::Log::Dispatch::Email $self = shift;

    $self->SUPER::log_message(@_);
}

sub send_email
{
    my $self = shift;
    my $class = ref $self;

    $self->SUPER::send_email(@_);
}

sub flush
{
    my Enigo::Common::Log::Dispatch::Email $self = shift;

    $self->SUPER::flush(@_);
}

sub DESTROY
{
    my Enigo::Common::Log::Dispatch::Email $self = shift;

    $self->SUPER::DESTROY(@_);
}

1;
