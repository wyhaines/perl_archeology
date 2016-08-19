#!/usr/bin/perl -wc
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: Base.pm

=head1

I<REVISION: $Revision: 1.1.1.1 $>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: 26 Sept 2001>

=head1 PURPOSE:

Provides a base class with some fundamental data and methods for
all Enigo::Common::Log::Dispatch objects.  This class is a
subclass of Log::Dispatch.

=head1 EXAMPLE:

=head1 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

package Enigo::Common::Log::Dispatch::Base;

use strict;
use base qw(Log::Dispatch::Base);
use vars qw($VERSION
        @_Log_Dispatch_levels
        @_our_levels
        %_level_map
        @EXPORT_OK);

use Enigo::Common::ParamCheck qw(paramCheck);

@_Log_Dispatch_levels = qw(debug
             info
             notice
             warning
             err
             error
             crit
             critical
             alert
             emerg
             emergency);

@_our_levels = qw(debug
          info
          minor
          major
          critical);

%_level_map = (debug => 'debug',
           1 => 'debug',
               info => 'info',
           2 => 'info',
           notice => 'info',
           3 => 'info',
               warning => 'minor',
           4 => 'minor',
           err => 'major',
               error => 'major',
           5 => 'major',
           crit => 'critical',
               critical => 'critical',
           6 => 'critical',
           alert => 'critical',
           7 => 'critical',
           emerg => 'critical',
           emergency => 'critical',
           8 => 'critical');

($VERSION) =
  '$Revision: 1.1.1.1 $' =~ /\$Revision:\s+([^\s]+)/; #'


######################################################################
##### Method: log_dispatch_levels
######################################################################

=pod

=head2 METHOD_NAME log_dispatch_levels

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 26 Sept 2001>

=head2 PURPOSE:

This method returns a list of the log levels originally defined within
the Log::Dispatch class.

=head2 ARGUMENTS:

None.

=head2 THROWS:

Nothing.

=head2 RETURNS:

A list of the original Log::Dispatch logging levels

=head2 EXAMPLE:

  @original_levels = $dispatcher->log_dispatch_levels;

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################
sub log_dispatch_levels {
  return @_Log_Dispatch_levels;
}


######################################################################
##### Method: levels
######################################################################

=pod

=head2 METHOD_NAME: levels

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 26 Sept 2001>

=head2 PURPOSE:

Returns the logging levels defined for Enigo applications.

=head2 ARGUMENTS:

None.

=head2 THROWS:

Nothing.

=head2 RETURNS:

A list of the logging levels defined for Enigo applications.

=head2 EXAMPLE:

  @levels = $dispatcher->levels;

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################


sub levels {
  return @_our_levels;
}


######################################################################
##### Method: map_level
######################################################################

=pod

=head2 METHOD_NAME: map_level

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 26 Sept 2001>

=head2 PURPOSE:

Takes a Log::Dispatch logging level and returns the equivalent
Enigo::Common::Log::Dispatch logging level.

=head2 ARGUMENTS:

A single scalar argument containing the Log::Dispatcher style
logging level that is to be mapped.  The level can either be
specified textually or numerically.  The argument can also be
passed via a hash reference with a key of LEVEL.

=head2 THROWS:

Nothing.

=head2 RETURNS:

A scalar value containing the logging level.

=head2 EXAMPLE:

  my $level = $dispatcher->map_level('notice');

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub map_level {
  my $self = shift;
  my ($param) = paramCheck([LEVEL => 'AN'],@_);

  use Data::Dumper;
  return $_level_map{$param->{LEVEL}};
}


######################################################################
##### Method: level_is_valid
######################################################################

=pod

=head2 METHOD_NAME: level_is_valid

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 27 Sept 2001>

=head2 PURPOSE:

Return a a true/false regarding whether the provided logging level
is a valid level or not.

=head2 ARGUMENTS:

Takes a single scalar argument containing the level to check.

=head2 THROWS:

Nothing.

=head2 RETURNS:

A scalar value containing either a true or a false response.

=head2 EXAMPLE:

  if (level_is_valied($level)) {#DO STUFF}

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub level_is_valid {
  my $self = shift;
  my $query_level = shift;

  foreach my $level (@_our_levels,@_Log_Dispatch_levels) {
    return 1 if lc($query_level) eq lc($level);
  }

  return undef;
}
1;
