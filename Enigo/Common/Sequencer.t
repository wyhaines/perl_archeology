#!/usr/bin/perl
#Version: $Revision: 1.1.1.1 $
#Date Modified: $Date: 2001/12/17 02:28:37 $

use strict;

use Enigo::TestTools qw(perl);

print "Testing Enigo::Common::Sequencer\n\n";

use vars qw($sequencer);

runTests(<<'ETESTS');
use Enigo::Common::Sequencer;
use Error qw(:try);

eval
  {
    $main::sequencer = new Enigo::Common::Sequencer();
  };
check('Creating a default sequencer works.',
      $@,
      $@);
;;;;;
my $error_text;
try {
    $main::sequencer = new Enigo::Common::Sequencer({START => 'abc',
                                            INTERVAL => -1});
  } catch Enigo::Common::Exception with {
    my $exception = shift;
    $error_text = "$exception";
  };
check('Attempt to create a new sequencer with an invalid start value properly triggers an exception.',
      !$error_text);
;;;;;
my $error_text;
try {
    $main::sequencer = new Enigo::Common::Sequencer({START => 100,
                                            INTERVAL => 'abc'});
  } catch Enigo::Common::Exception with {
    my $exception = shift;
    $error_text = "$exception";
  };
check('Attempt to create a new sequencer with an invalid interval value is properly triggers an exception.',
      !$error_text);
;;;;;
my $error_text;
try
  {
    $main::sequencer = Enigo::Common::Sequencer->new({START => 100,
                                            INTERVAL => -1});
  }
catch Enigo::Common::Exception::ParamCheck with
  {
    my $exception = shift;
    $error_text = "$exception";
  };
check('Attempt to create a new sequencer with valid non-default start value and interval value works as is expected.',
      $error_text,
      $error_text);
;;;;;
check('getCurrentSequenceNumber() works.',
      $main::sequencer->getCurrentSequenceNumber() != 100,
      diff($main::sequencer->getCurrentSequenceNumber(),100));
;;;;;
check('gextNextSequenceNumber() works.',
      $main::sequencer->getNextSequenceNumber() != 99,
      diff($main::sequencer->getCurrentSequenceNumber(),99));
ETESTS
