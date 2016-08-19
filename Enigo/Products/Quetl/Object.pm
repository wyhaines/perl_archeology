#!/usr/bin/perl -wc
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: Object.pm

=head1

I<REVISION: .1>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: 01 Jan 2000>

=head1 PURPOSE:

Provides an invocation layer object to call object methods on an
RPC server.

=head1 EXAMPLE:

=head1 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

package Enigo::Products::Quetl::Object;

use strict;

use vars qw($AUTOLOAD);
$Enigo::Products::Quetl::Object::VERSION = '.1';



sub AUTOLOAD {
  my $method = $AUTOLOAD;
  my $index;
  die "Cannot parse method: $method"
    unless ($index = rindex($method, '::')) != -1;
  my $class = substr($method, 0, $index);
  $method = substr($method, $index+2);
  eval <<"ECODE";
  package $class;
  sub $method {
    my \$self = shift;
    my \$client = \$self->{CLIENT};
    my \$object = \$self->{OBJECT};
    my \@result = \$client->Call({SERVICE => 'CallMethod',
                                  USER => '$self->{USER}',
                                  DATA => [\$object, '$method',\@_]});
    return \@result if wantarray;
    return \$result[0];
  }
ECODE
    goto &$AUTOLOAD;
}



sub new {
  my $class = shift;
  my ($param) = paramCheck([CLASS => 'U',
                CLIENT => 'U',
                OBJECT => 'U',
                USER => 'AN'],@_);

  $class = ref($class) if ref($class);
  no strict 'refs';
  my $ocl = "${class}::$param->{CLASS}";
  @{"${ocl}::ISA"} = $class unless @{"${ocl}::ISA"};
  my $self = {CLIENT => $param->{CLIENT},
          OBJECT => $param->{OBJECT},
          USER => $param->{USER}};

  use strict 'refs';
  bless($self, $ocl);
  return $self;
}


sub DESTROY {
  my $self = shift;
  if (my $client = delete $self->{CLIENT}) {
    eval {$client->Call({SERVICE => DestroyHandle,
             USER => $self->{USER},
             DATA => $self->{OBJECT}})};
  }
}


1;
