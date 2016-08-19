#!perl
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: pingDB.pm

=head1

I<REVISION: 1>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: 21 Mar 2001>

=head1 PURPOSE:

Pings a database in order to determine if the connection to it
is still alive.  If the connection is no longer alive, a notice
will be sent out about this, and there will be an attempt to
reconnect to the database.

=head1 EXAMPLE:

=head1 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

use strict;
use Enigo::Common::ParamCheck qw(paramCheck);

sub pingDB {
  my ($param) = paramCheck([DBH => 'U',
                DSN => 'U',
                RECIPIENTS => 'AR',
                RECONNECT_INTERVAL => ['N',60],
                RETRIES => ['N',3]],@_);
  my $commit_interval;

  return undef unless (ref($param->{DBH}) =~ /DBI/);

  my $ping;
  eval {
    $ping = $param->{DBH}->ping();
  };
  unless ($ping) {
    my $time = sfmt_time();
    mail({SUBJECT => "db connection $param-<{DSN} is down; attempting to reconnect",
      RECIPIENTS => $param->{RECIPIENTS},
      BODY => <<EMAIL});
The connection to $param->{DSN} is down at $time.

Attempting to reconnect.  Stay tuned....


Sincerely,

The Build Log Loader, c/o Quetl
EMAIL

    $param->{DBH} = undef;
    sleep $param->{RECONNECT_INTERVAL};

    for my $j (1..$param->{RETRIES}) {
      ($param->{DBH},$commit_interval) = dbInit({DSN => $param->{DSN}});
      last if $param->{DBH};
      sleep $param->{RECONNECT_INTERVAL};
    }

    if ($param->{DBH}) {
      my $time = sfmt_time();
      mail({SUBJECT => "connection to $param->{DSN} successful",
        RECIPIENTS => $param->{RECIPIENTS},
        BODY => <<EMAIL});
The connection to $param->{DSN} was reestablished at $time.


Sincerely,

The Build Log Loader, c/o Quetl
EMAIL
      return wantarray ? $param->{DBH} : ($param->{DBH},$param->{DSN});
    } else {
      my $time = sfmt_time();
      mail({SUBJECT => "connection to $param->{DSN} still down",
        RECIPIENTS => $param->{RECIPIENTS},
        BODY => <<EMAIL});
The connection to $param->{DSN} is still down at $time.


Sincerely,

The Build Log Loader, c/o Quetl
EMAIL
    }
  } else {
    return wantarray ? ($param->{DBH},$param->{DSN}) : $param->{DBH};
  }
  return undef;
}


1;
