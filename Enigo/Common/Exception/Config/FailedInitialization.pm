#!/usr/bin/perl -c
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: $RCSfile: FailedInitialization.pm,v $

=head1 Enigo::Common::Exception::Config::FailedInitialization

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
package Enigo::Common::Exception::Config::FailedInitialization;

use strict;

require Enigo::Common::Exception::Config;
use Text::Wrap qw();

@Enigo::Common::Exception::Config::FailedInitialization::ISA =
  qw(Enigo::Common::Exception::Config);
$Enigo::Common::Exception::Config::FailedInitialization::VERSION =
  '$Revision: 1.1.1.1 $ ' =~ /\$Revision:\s+([^\s]+)/;


######################################################################
##### Constructor: new
######################################################################

=pod

=head2 CONSTRUCTOR_NAME: new

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 22 JUN 2000>

=head2 PURPOSE:

To return an Enigo::Common::Exception::Config::FailedInitialization exception.

=head2 ARGUMENTS:

Takes either two (or three) scalar arguments, the config catalog that
was being used, the config that was going to be read, and, optionally,
the value of the exception, or takes a hashref with CATALOG, CONFIG, and,
optionally, VALUE, as parameters.  Value defaults to 1 if not provided.

If an attempt to read a specific config has not yet occured, CONFIG may
be omitted.

=head2 RETURNS:

An hash blessed into Enigo::Common::Exception::Config::FailedInitialization.

=head2 EXAMPLE:

  throw Enigo::Common::Exception::Config::FailedInitialization
    ({CONFIG => 'Balthazar',
      CATALOG => '/usr/local/share/catalog'});

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

    my $param = {CATALOG => '',
                 CONFIG => '',
         VALUE => 1};

    if (ref($_[0]) eq 'HASH')
      {
    $param->{CATALOG} = $_[0]->{CATALOG};
        $param->{CONFIG} = $_[0]->{CONFIG};
        $param->{VALUE} = exists $_[0]->{VALUE} ? $_[0]->{VALUE} :
                                              $param->{VALUE};
      }
    else
      {
    $param->{CATALOG} = $_[0];
        $param->{CONFIG} = $_[1];
        $param->{VALUE} = defined $_[2] ? $_[2] :  $param->{VALUE};
      }

    my @args;

    my $config_text = $param->{CONFIG}
      ? " and reading config, $param->{CONFIG}," :
        '';
    my $text = Text::Wrap::wrap('','    ',<<ETXT);
ConfigError: FailedInitialization: initialization of an Enigo::Common::Config object using config catalog, $param->{CATALOG},$config_text failed.
<ERROR_LOCATION/>
ETXT
    return(bless Enigo::Common::Exception->new
       ({TEXT => $text,
         VALUE => $param->{VALUE}}),
       $self);
  }

1;
