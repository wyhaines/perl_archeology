#!/usr/bin/perl -wc
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: $RCSfile: ApacheLog.pm,v $

=head1

I<REVISION: $Revision: 1.1.1.1 $>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: $Date: 2001/12/17 02:28:37 $>

=head1 PURPOSE:

Overrides Log::Dispatch::ApacheLog to get it to inherit from our
overriding parents.

=head1 EXAMPLE:

=head1 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

package Enigo::Common::Log::Dispatch::ApacheLog;

use strict;
use vars qw(@ISA $VERSION);

use base qw(Enigo::Common::Log::Dispatch::Output);
require Log::Dispatch::ApacheLog;
push @ISA,'Log::Dispatch::Apachelog';

use fields qw(apache_log);

use Apache::Log;

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
    $self->{apache_log} = UNIVERSAL::isa( $params{apache}, 'Apache::Server' ) ? $params{apache}->log : $params{apache}->log;

    return $self;
}

sub log_message {
  my Enigo::Common::Log::Dispatch::ApacheLog $self = shift;
  $self->SUPER::log_message(@_);
}

1;
