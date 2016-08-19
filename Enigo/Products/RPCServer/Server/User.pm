#!/usr/bin/perl -wc
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: $RCSfile: User.pm,v $

=head1 Enigo::Products::RPCServer::Server::User;

I<REVISION: $Revision: 1.1.1.1 $>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: $Date: 2001/12/17 02:28:37 $>

=head1 PURPOSE:

=head1 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

package Enigo::Products::RPCServer::Server::User;

use strict;
use vars qw($VERSION @ISA);

use Enigo::Common::MethodHash;
use Enigo::Common::ParamCheck qw(paramCheck);

@ISA = qw(Enigo::Common::MethodHash);

$VERSION = '$Revision: 1.1.1.1 $' =~ /\$Revision:\s+([^\s]+)/; #'


######################################################################
##### Constructor: new
######################################################################

=pod

=head2 CONSTRUCTOR_NAME: new

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: >

=head2 PURPOSE:

Returns a blessed hashref.

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
  my ($proto) = shift;
  my ($class) = ref($proto) || $proto;
  my $self  = Enigo::Common::MethodHash->new();
  bless ($self, $class);
  $self->_init(@_);
  return $self;
}


######################################################################
##### Method: _init
######################################################################

=pod

=head2 METHOD_NAME: _init

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 01 Nov 2001>

=head2 PURPOSE:

Does initializations such as setting the object variables.

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

sub _init {
  my ($self) = shift;
  my ($param) = paramCheck([NAME => 'U',
                PASSWORD => 'U',
                ENCRYPTION_ALGORITHM => 'U',
                ENCRYPTION_KEY => 'U'],@_) if scalar(@_);

  $self->NAME($param->{NAME})
       ->PASSWORD($param->{PASSWORD})
       ->ENCRYPTION_ALGORITHM($param->{ENCRYPTION_ALGORITHM})
       ->ENCRYPTION_KEY($param->{ENCRYPTION_KEY});
}


1;
