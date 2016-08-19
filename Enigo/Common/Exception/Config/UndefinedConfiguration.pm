#!/usr/bin/perl -c
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: $RCSfile: UndefinedConfiguration.pm,v $

=head1 Enigo::Common::Exception::Config::UndefinedConfiguration

I<REVISION:$Revision: 1.1.1.1 $>

I<AUTHOR: $Author: khaines $>

I<DATE_MODIFIED: $Date: 2001/12/17 02:28:37 $>

=head1 PURPOSE:

This is an exception intended to be thrown by Config.pm when an
attempt is made to read a configuration that is not defined in
the config catalog.

=head1 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################
package Enigo::Common::Exception::Config::UndefinedConfiguration;

use strict;

require Enigo::Common::Exception::Config;
use Text::Wrap qw();

@Enigo::Common::Exception::Config::UndefinedConfiguration::ISA =
  qw(Enigo::Common::Exception::Config);
$Enigo::Common::Exception::Config::UndefinedConfiguration::VERSION =
  '$Revision: 1.1.1.1 $ ' =~ /\$Revision:\s+([^\s]+)/;


######################################################################
##### Constructor: new
######################################################################

=pod

=head2 CONSTRUCTOR_NAME: new

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 22 JUN 2000>

=head2 PURPOSE:

To return an Enigo::Common::Exception::Config::UndefinedConfiguration exception.

=head2 ARGUMENTS:

Takes either oneo (or two) scalar arguments, the name of the config
that is undefined, and, optionally, the VALUE of the
exception, or takes a hashref with CONFIG, and, optionally, VALUE,
as parameters.  Value defaults to 1 if not provided.

=head2 RETURNS:

An hash blessed into Enigo::Common::Exception::Config::UndefinedConfiguration.

=head2 EXAMPLE:

  throw Enigo::Common::Exception::Config::UndefinedConfiguration
    ({CONFIG => 'Balthazar'});

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub new
  {
    my ($self) = shift;

    my $param = {CONFIG => '',
         VALUE => 1};

    if (ref($_[0]) eq 'HASH')
      {
    $param->{CONFIG} = $_[0]->{CONFIG};
        $param->{VALUE} = exists $_[0]->{VALUE} ? $_[0]->{VALUE} :
                                              $param->{VALUE};
      }
    else
      {
    $param->{CONFIG} = $_[0];
        $param->{VALUE} = defined $_[1] ? $_[1] :  $param->{VALUE};
      }

    my @args;

    my $text = Text::Wrap::wrap('','    ',<<ETXT);
ConfigError: UndefinedConfiguration: the configuration, $param->{CONFIG}, is not defined
<ERROR_LOCATION/>
ETXT
    return(bless Enigo::Common::Exception->new
       ({TEXT => $text,
         VALUE => $param->{VALUE}}),
       $self);
  }

1;
