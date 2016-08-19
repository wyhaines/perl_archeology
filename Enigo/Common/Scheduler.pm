#!/usr/bin/perl -wc
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME:

=head1

I<REVISION: $Revision: 1.1.1.1 $>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: $Date: 2001/12/17 02:28:37 $>

=head1 PURPOSE:

=head1 EXAMPLE:

=head1 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

package Enigo::Common::Scheduler;

use Enigo::Common::Exception qw(:IO);
use Enigo::Common::ParamCheck qw(paramCheck);
use Time::ParseDate;
use Data::Dumper;

use strict;

$Enigo::Common::Scheduler::VERSION = '.1';

my $DEBUG = 0;

my @WDAYS = qw(Sunday
           Monday
           Tuesday
           Wednesday
           Thursday
           Friday
           Saturday
           Sunday);

my @ALPHACONV = ({}.
         {},
         {},
         {},
         {qw(jan 1 feb 2 mar 3 apr 4 may 5 jun 6 jul 7 aug 8
             sep 9 oct 10 nov 11 dec 12) },
         {qw(sun 0 mon 1 tue 2 wed 3 thu 4 fri 5 sat 6)});
my @RANGES = ([0,59],
          [0,59],
          [0,23],
          [0,31],
          [0,12],
          [0,7]);

my @LOWMAP = ({},
          {},
          {},
          { 0 => 1},
          { 0 => 1},
          { 7 => 0});


######################################################################
##### Constructor: new
######################################################################

=pod

=head2 CONSTRUCTOR_NAME: new

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 31 Dec 2000>

=head2 PURPOSE:

Creates a new scheduler object.

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
  my $class = shift;
  my $config = ref($_[0]) eq "HASH" ? $_[0] : {  @_ };
  my $self = {QUEUE => [],
          TIME_TABLE => {},
          INTERVAL_TABLE => {}};
  bless $self,(ref($class) || $class);

  $self->loadCrontab() if $config->{file};
  return $self;
}



######################################################################
##### Method: addEntry
######################################################################

=pod

=head2 METHOD_NAME: addEntry

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 31 Dec 2000>

=head2 PURPOSE:

Adds an entry into the table of time entries.

=head2 ARGUMENTS:

Takes a hash reference with two keys, TIME and LABEL.  TIME is the
schedule specification for the entry, and LABEL is a unique label
to identify the entry.

=head2 THROWS:

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

sub addEntry {
  my $self = shift;
  my ($param) = paramCheck([TIME => 'U',
                LABEL => 'AN'],@_);

  $self->{TIME_TABLE}->{$param->{LABEL}} = $param->{TIME};

  return undef;
}



######################################################################
##### Method: getEntry
######################################################################

=pod

=head2 METHOD_NAME: getEntry

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 31 Dec 2000>

=head2 PURPOSE:

Returns a single scheduling entry.

=head2 ARGUMENTS:

Takes a hash reference with a key of LABEL, the value of which is
the ID of the entry to return.

=head2 THROWS:

nothing

=head2 RETURNS:

A scalar containing the requested entry, or undef if there was
no matching entry.

=head2 EXAMPLE:

  my $entry = $self->getEntry('cronit');

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub getEntry {
  my $self = shift;
  my ($param) = paramCheck([LABEL => 'AN'],@_);

  return $self->{TIME_TABLE}->{$param->{LABEL}};
}



######################################################################
##### Method: getEntries
######################################################################

=pod

=head2 METHOD_NAME: getEntries

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 31 Dec 2000>

=head2 PURPOSE:

Returns a hash of all of the entries, indexed on the labels of
each of the entries.

=head2 ARGUMENTS:

nothing

=head2 THROWS:

=head2 RETURNS:

A hash of all of the entries.

=head2 EXAMPLE:

  my %entries = $self->getEntries();

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub getEntries {
  my $self = shift;

  return %{$self->{TIME_TABLE}};
}



######################################################################
##### Method: deleteEntry
######################################################################

=pod

=head2 METHOD_NAME: deleteEntry

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 31 Dec 2000>

=head2 PURPOSE:

Deletes a scheduling entry from the list of entries.

=head2 ARGUMENTS:

Takes a hash reference with a key of LABEL, the value of which
is the label of the entry to delete.

=head2 THROWS:

=head2 RETURNS:

The value of the entry deleted.

=head2 EXAMPLE:

  my $value = $self->deleteEntry({LABEL => 'cronit'});

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub deleteEntry {
  my $self = shift;
  my ($param) = paramCheck([LABEL => 'AN'],@_);

  return delete($self->{TIME_TABLE}->{$param->{LABEL}});
}



######################################################################
##### Method: cleanEntries
######################################################################

=pod

=head2 METHOD_NAME: cleanEntries

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 31 Dec 2000>

=head2 PURPOSE:

Purges all of the scheduling entries.

=head2 ARGUMENTS:

none

=head2 THROWS:

nothing

=head2 RETURNS:

nothing

=head2 EXAMPLE:

  $self->cleanEntries();

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub cleanEntries {
  my $self = shift;
  $self->{TIME_TABLE} = {};
}



######################################################################
##### Method: getQueue
######################################################################

=pod

=head2 METHOD_NAME: getQueue

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 31 Dec 2000>

=head2 PURPOSE:

Returns the current scheduling queue.

=head2 ARGUMENTS:

none

=head2 THROWS:

nothing

=head2 RETURNS:

The current scheduling queue as an array reference.

=head2 EXAMPLE:

  my $queue = $self->getQueue();

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub getQueue {
  return shift->{QUEUE};
};



######################################################################
##### Method: checkQueue
######################################################################

=pod

=head2 METHOD_NAME: checkQueue

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 31 Dec 2000>

=head2 PURPOSE:

Checks the scheduling queue for impending events.

=head2 ARGUMENTS:

none

=head2 THROWS:

nothing

=head2 RETURNS:

Returns an array containing two array references.  The first
contains the queue entry or entries for the next event(s) that
are upcoming in the schedule.  Normally only a single entry
will be contained in the first array reference, but if there
are multiple events scheduled for the same second, entries for
each will be returned.

The second array reference contains the entries for any entries
which were in the queue but have expired (the time they were
scheduled for has passed).

=head2 EXAMPLE:

my ($upcoming,$expired) = $self->checkQueue();

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub checkQueue {
  my $self= shift;

  my $current = [];
  my $expired = [];
  my $now = time();
  my $update_flag = 0;
  do {
    if ($self->{QUEUE}->[0]->[1] <= $now) {
      my $id = $self->{QUEUE}->[0]->[0];
      push(@{$expired},shift(@{$self->{QUEUE}}));
      $self->updateQueue({ID => $id});
    };
  } until ($self->{QUEUE}->[0]->[1] > $now);

  foreach my $item (@{$self->{QUEUE}}) {
    if ($item->[1] == $self->{QUEUE}->[0]->[1]) {
      push(@{$current},$item);
    }

    return ($current,$expired);
  }
}



######################################################################
##### Method: getNextExecutionTime
######################################################################

=pod

=head2 METHOD_NAME: getNextExecutionTime

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 31 Dec 2000>

=head2 PURPOSE:

Returns the next execution time for a given entry.

=head2 ARGUMENTS:

Takes a hash reference with two keys, ENTRY and TIME.

ENTRY is a fully expanded scheduling entry.  i.e.
'0 30 * * * *'

TIME is the time, in seconds since the epoch, to calculate the
next execution time from.  If it is not provided, the current
time is assumed.

=head2 THROWS:

nothing

=head2 RETURNS:

A scalar containing the next execution time, in seconds since
the epoch.

=head2 EXAMPLE:

 my $next_time = $scheduler->getNextExecutionTime
  ({ENTRY => '0 30 * * * *'});

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub getNextExecutionTime {
  my $self = shift;
  my ($param) = paramCheck([ENTRY => 'U',
                TIME => 'UO'],@_);

  my $cron_entry = $param->{ENTRY};
  my @expanded;
  my $w;

  for my $i (0..5) {
    my @e = split /,/,$cron_entry->[$i];
    my @res;
    while (defined(my $t = shift @e)) {
      if ($t =~ m|^([^-]+)-([^-/]+)(/(.*))?$|) {
    my ($low,$high,$step) = ($1,$2,$4);
    $step = 1 unless $step;
    if ($low !~ /^(\d+)/) {
      $low = $ALPHACONV[$i]{lc $low};
    }
    if ($high !~ /^(\d+)/) {
      $high = $ALPHACONV[$i]{lc $high};
    }
    if (! defined($low) or
        !defined($high) or
        $low > $high or
        $step !~ /^\d+$/) {
      die "Invalid cronentry '",$cron_entry->[$i],"'";
    }
    my $j;
    for ($j = $low; $j <= $high; $j += $step) {
      push @e,$j;
    }
      } else {
    $t = $ALPHACONV[$i]{lc $t} if $t !~ /^(\d+|\*)$/;
    $t = $LOWMAP[$i]{$t} if exists($LOWMAP[$i]{$t});

    die "Invalid cronentry '",$cron_entry->[$i],"'" 
      if (!defined($t) or
          ($t ne '*' and ($t < $RANGES[$i][0] or $t > $RANGES[$i][1])));
    push @res,$t;
      }
    }
    push @expanded, [ sort { $a <=> $b} @res];
  }

  # Calculating time:
  # =================
  my $now = $param->{TIME} ? $param->{TIME} : time();

  if ($expanded[3]->[0] ne '*' and $expanded[5]->[0] ne '*') {
    # Special check for which time is lower (Month-day or Week-day spec):
    my @bak = @{$expanded[4]};
    $expanded[5] = [ '*' ];
    my $t1 = $self->_calcTime({NOW => $now,
                   EXPANDED => \@expanded});
    $expanded[5] = \@bak;
    $expanded[3] = [ '*' ];
    my $t2 = $self->_calcTime({NOW => $now,
                   EXPANDED => \@expanded});
    return $t1 < $t2 ? $t1 : $t2;
  } else {
    # No conflicts possible:
    return $self->_calcTime({NOW => $now,
                 EXPANDED => \@expanded});
  }
}

# ==================================================
# PRIVATE METHODS:
# ==================================================

# Build up executing queue and delete any
# existing entries
sub buildInitialQueue {
  my $self = shift;
  $self->{QUEUE} = [];

  foreach my $id (keys(%{$self->{TIME_TABLE}})) {
    $self->updateQueue({ID => $id});
  }
}


# Udate the scheduler queue with a new entry
sub updateQueue {
  my $self = shift;
  my ($param) = paramCheck([ID => 'AN'],@_);

  my $entry = $self->{TIME_TABLE}->{$param->{ID}};
  if ($entry =~ /^\d+$/) {
    my $old_time = $self->{INTERVAL_TABLE}->{$param->{ID}};
    my @old_time;
    unless ($old_time =~ /^\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\*$/)
      {
    @old_time = (localtime(time()))[0..5];
    $old_time[5] += 1900;
    $old_time[4] += 1;
      } else {
    @old_time = localtime($old_time);
      }

  sprintf("%2.2d:%2.2d:%2.2d %4.4d/%2.2d/%2.2d",
      $old_time[2],
      $old_time[1],
      $old_time[0],
      $old_time[5],
      $old_time[4],
      $old_time[3]),"\n";
  ($entry +
   parsedate
   (sprintf("%2.2d:%2.2d:%2.2d %4.4d/%2.2d/%2.2d",
        $old_time[2],
        $old_time[1],
        $old_time[0],
        $old_time[5],
        $old_time[4],
        $old_time[3]))),"\n";

    my $new_time_seconds = ($entry +
                parsedate
                (sprintf("%2.2d:%2.2d:%2.2d %4.4d/%2.2d/%2.2d",
                     $old_time[2],
                     $old_time[1],
                     $old_time[0],
                     $old_time[5],
                     $old_time[4],
                     $old_time[3])));
    my @new_time = localtime($new_time_seconds);
    $new_time[5] += 1900;
    $new_time[4]++;
    $entry = join(' ',@new_time[0..4],'*');
    $self->{INTERVAL_TABLE}->{$param->{ID}} = $new_time_seconds;
  }

  $entry = [split(/\s+/,$entry)];

  my $new_time = $self->getNextExecutionTime({ENTRY => $entry});
  $self->{QUEUE} = [sort { $a->[1] <=> $b->[1] }
            @{$self->{QUEUE}},[$param->{ID},$new_time]];
}



######################################################################
##### Method: _calcTime
######################################################################

=pod

=head2 METHOD_NAME: _calcTime

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 31 Dec 2000>

=head2 PURPOSE:

This is the heart of the scheduler.  It calculates the next
execution time for a given entry.

=head2 ARGUMENTS:

Expects a hash reference with two keys, NOW and EXPANDED.

NOW is the time to calculate from, represented as seconds since
the epoch.

EXPANDED is an array reference containing a scheduling entry,
broken up so that each field is in a seperate element in the
array reference.

=head2 THROWS:

nothing

=head2 RETURNS:

A scalar containing a time.

=head2 EXAMPLE:

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub _calcTime {
  my $self = shift;
  my ($param) = paramCheck([NOW => 'I',
                EXPANDED => 'AR'],@_);

  my ($now_sec,
      $now_min,
      $now_hour,
      $now_mday,
      $now_mon,
      $now_wday,
      $now_year) = (localtime($param->{NOW}+1))[0,1,2,3,4,6,5];
  $now_mon++;
  $now_year += 1900;

  # Notes on variables set:
  # $now_... : the current date, fixed at call time
  # $dest_...: date used for backtracking. At the end, it contains
  #            the desired lowest matching date

  my ($dest_sec,
      $dest_mon,
      $dest_mday,
      $dest_wday,
      $dest_hour,
      $dest_min,
      $dest_year) = ($now_sec,
             $now_mon,
             $now_mday,
             $now_wday,
             $now_hour,
             $now_min,
             $now_year);

  while ($dest_year <= $now_year + 1) { # Airbag...
    # Check month:
    if ($param->{EXPANDED}->[4]->[0] ne '*') {
      unless (defined ($dest_mon = $self->getNearest({X => $dest_mon,
                               TO_CHECK => $param->{EXPANDED}->[4]}))) {
    $dest_mon = $param->{EXPANDED}->[4]->[0];
    $dest_year++;
      }
    }

    # Check for day of month:
    if ($param->{EXPANDED}->[3]->[0] ne '*') {      
      if ($dest_mon != $now_mon) {  
    $dest_mday = $param->{EXPANDED}->[3]->[0];
      } else {
    unless (defined ($dest_mday = $self->getNearest({X => $dest_mday,
                              TO_CHECK => $param->{EXPANDED}->[3]}))) {
      # Next day matched is within the next month. ==> redo it
      $dest_mday = $param->{EXPANDED}->[3]->[0];
      $dest_mon++;
      if ($dest_mon > 12) {
        $dest_mon = 1;
        $dest_year++;
      }

      next;
    }
      }
    } else {
      $dest_mday = ($dest_mon == $now_mon ? $dest_mday : 1);
    }

    # Check for day of week:
    if ($param->{EXPANDED}->[5]->[0] ne '*') {
      $dest_wday = $self->getNearest({X => $dest_wday,
                       TO_CHECK => $param->{EXPANDED}->[5]});
      $dest_wday = $param->{EXPANDED}->[5]->[0] unless $dest_wday;

      my ($mon,$mday,$year);

      $dest_mday = 1 if $dest_mon != $now_mon;
      my $t = parsedate(sprintf("%4.4d/%2.2d/%2.2d",
                $dest_year,
                $dest_mon,
                $dest_mday));
      ($mon,$mday,$year) = 
    (localtime(parsedate("$WDAYS[$dest_wday]",PREFER_FUTURE=>1,NOW=>$t-1)))[4,3,5];
      $mon++;
      $year += 1900;


      if ($mon != $dest_mon || $year != $dest_year) {
    $dest_mon = $mon;
    $dest_year = $year;
    $dest_mday = 1;
    $dest_wday = (localtime(parsedate(sprintf("%4.4d/%2.2d/%2.2d",
                          $dest_year,
                          $dest_mon,
                          $dest_mday))))[6];
    next;
      }

      $dest_mday = $mday;
    } else {
      unless ($dest_mday) {
    $dest_mday = ($dest_mon == $now_mon ? $dest_mday : 1);
      }
    }

    # Check for hour
    if ($param->{EXPANDED}->[2]->[0] ne '*') {
      if ($dest_mday != $now_mday) {
    $dest_hour = $param->{EXPANDED}->[2]->[0];
      } else {
    unless (defined ($dest_hour = $self->getNearest({X => $dest_hour,
                              TO_CHECK => $param->{EXPANDED}->[2]}))) {
      # Hour to match is at the next day ==> redo it
      $dest_hour = $param->{EXPANDED}->[2]->[0];
      my $t = parsedate(sprintf("%2.2d:%2.2d:%2.2d %4.4d/%2.2d/%2.2d",
                    $dest_hour,
                    $dest_min,
                    $dest_sec,
                    $dest_year,
                    $dest_mon,
                    $dest_mday));
      ($dest_mday,$dest_mon,$dest_year,$dest_wday) = 
        (localtime(parsedate("+ 1 day",NOW=>$t)))[3,4,5,6];
      $dest_mon++;
      $dest_year += 1900;
      next;
    }
      }
    } else {
      $dest_hour = ($dest_mday == $now_mday ? $dest_hour : 0);
    }

    # Check for minute
    if ($param->{EXPANDED}->[1]->[0] ne '*') {
      if ($dest_hour != $now_hour) {
    $dest_min = $param->{EXPANDED}->[1]->[0];
      } else {
    unless (defined ($dest_min = $self->getNearest({X => $dest_min,
                             TO_CHECK => $param->{EXPANDED}->[1]}))) {
      # Minute to match is at the next hour ==> redo it
      $dest_min = $param->{EXPANDED}->[1]->[0];
      my $t = parsedate(sprintf("%2.2d:%2.2d:%2.2d %4.4d/%2.2d/%2.2d",
                    $dest_hour,
                    $dest_min,
                    $dest_sec,
                    $dest_year,
                    $dest_mon,
                    $dest_mday));
      ($dest_hour,$dest_mday,$dest_mon,$dest_year,$dest_wday) = 
        (localtime(parsedate(" + 1 hour",NOW=>$t)))  [2,3,4,5,6];
      $dest_mon++;
      $dest_year += 1900;
      next;
    }
      }
    } else {
      $dest_min = ($dest_hour == $now_hour ? $dest_min : 0);
    }


    # Check for second
    if ($param->{EXPANDED}->[0]->[0] ne '*') {
      if ($dest_min != $now_min) {
    $dest_sec = $param->{EXPANDED}->[0]->[0];
      } else {
    unless (defined ($dest_sec = $self->getNearest({X => $dest_sec,
                             TO_CHECK => $param->{EXPANDED}->[0]}))) {
      # Minute to match is at the next hour ==> redo it
      $dest_sec = $param->{EXPANDED}->[0]->[0];
      my $t = parsedate(sprintf("%2.2d:%2.2d:%2.2d %4.4d/%2.2d/%2.2d",
                    $dest_hour,
                    $dest_min,
                    $dest_sec,
                    $dest_year,
                    $dest_mon,
                    $dest_mday));
      ($dest_min,$dest_hour,$dest_mday,$dest_mon,$dest_year,$dest_wday) = 
        (localtime(parsedate(" + 1 minute",NOW=>$t))) [1,2,3,4,5,6];
      $dest_mon++;
      $dest_year += 1900;
      next;
    }
      }
    } else {
      $dest_sec = ($dest_min == $now_min ? $dest_sec : 0);
    }


    # We did it !!
    $WDAYS[$dest_wday];
    return parsedate(sprintf("%2.2d:%2.2d:%2.2d %4.4d/%2.2d/%2.2d",
                 $dest_hour,$dest_min,$dest_sec,$dest_year,$dest_mon,$dest_mday));
  }
}

# get next entry in list or 
# undef if is the highest entry found
sub getNearest {
  my $self = shift;
  my ($param) = paramCheck([X => 'I',
                TO_CHECK => 'AR'],@_);

  foreach my $i (0 .. $#{$param->{TO_CHECK}}) {
    if (@{$param->{TO_CHECK}}->[$i] >= $param->{X}) {
      return @{$param->{TO_CHECK}}->[$i];
    }
  }
  return undef;
}


1;
