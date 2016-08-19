#!/usr/bin/perl
#Version: $Revision: 1.1.1.1 $
#Date Modified: $Date: 2001/12/17 02:28:37 $

use strict;

use Enigo::TestTools qw(perl);

print "Testing Enigo::Common::Scheduler\n\n";

use vars qw($scheduler);

runTests(<<'ETESTS');
use Enigo::Common::Scheduler;

eval {
    $main::scheduler = new Enigo::Common::Scheduler();
};
check('Creating an empty scheduler object works.',
      $@,
      $@);
;;;;;
eval {
    $main::scheduler->addEntry({TIME => '7 * * * * *',
                           LABEL => 'test1'});
};
check('Adding a basic scheduling entry works.',
      $@,
      $@);
;;;;;
eval {
    $main::scheduler->addEntry({TIME => '0-59/5 * * * * *',
                           LABEL => 'test2'});
};
check('Adding a scheduling entry with a range works.',
      $@,
      $@);
;;;;;
eval {
    $main::scheduler->addEntry({TIME => '90',
                           LABEL => 'test3'});
};
check('Adding an interval entry works.',
      $@,
      $@);
;;;;;
eval {
    print STDERR "Waiting for the top of the minute to build the queue (",
      (60 - (time() % 60)),
      " secs)...";
    while ((time() % 60) ne 0) {
      print STDERR '.';
      sleep(1);
    }
    print STDERR "\n";
    $main::scheduler->buildInitialQueue();
};
check('Built initial queue.',
      $@,
      $@);
;;;;;
eval {
    print STDERR "Running through the queue.  This should take about 90 seconds.\n";
    my %events;
    my $initiation = time();
    while (scalar(keys(%events)) < 3) {
      my ($pending) = $main::scheduler->checkQueue();
      sleep($pending->[0]->[1]-time());
      print STDERR "$pending->[0]->[0] is up (",($pending->[0]->[1] % 60),")\n";
      $events{$pending->[0]->[0]}++;
    }
};
check('Ran through the queue correctly.',
      $@,
      $@);
ETESTS
