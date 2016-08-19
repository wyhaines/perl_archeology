#!/usr/bin/perl
#Version: $Revision: 1.1.1.1 $
#Date Modified: $Date: 2001/12/17 02:28:37 $

use strict;

use Enigo::TestTools qw(perl);
use Enigo::Common::Override {exit => ['Enigo::Common::Exception']};
use Enigo::Common::SQL::SQL;
use IO::Scalar;

print "Testing Enigo::Common::Config\n\n";

#####
#// Generate the config and config catalog.
#####

my $testdir = writeDir("/tmp/configtest.$$");
$testdir->writeFile("/tmp/configtest.$$/catalog",<<ECATALOG);
#####
#// Test config catalog.  This is autogenerated by the Config.t test suite,
#// and it should be autodeleted when the tests complete.
#####
test1 = /tmp/configtest.$$/test1.conf
test2 = /tmp/configtest.$$/test2.conf
ECATALOG

$testdir->writeFile("/tmp/configtest.$$/test1.conf",<<'ETEST1');
#####
#// Test configuration file.  This is autogenerated by the Config.t test
#// suite, and it should be autodeleted when the tests are complete.
#####
dog = kangal
cat = bengal
goat = kinder
goat = angora
ETEST1

$testdir->writeFile("/tmp/configtest.$$/test2.conf",<<'ETEST2');
#####
#// Test configuration file.  This is autogenerated by the Config.t test
#// suite, and it should be autodeleted when the tests are complete.
#####
%if [!--date today--] < [!--date today at 7:00 am--]
start = now
%else
start = later
%fi
ETEST2

use vars qw($config);
my @tests = split(/;;;;;/,<<'ETESTS');
eval {
  $main::config = Enigo::Common::Config->new();
};
check('Creation of a configuration object is successful.',
      $@,
      $@);
;;;;;
eval {
  $main::config->parse("/tmp/configtest.$$/catalog");
};
check('Parsing of a catalog file works.',
      $@,
      $@);
;;;;;
eval {
  $main::config->read('test1');
};
check('Reading a simple configuration file is successful.',
      $@,
      $@);
;;;;;
my $dog;
my $cat;
my $goat;
eval {
  $dog = $main::config->get('dog');
  $cat = $main::config->get('cat');
  $goat = $main::config->get('goat');
};
check('The expected data was retrieved from the configuration file.',
      !($dog eq 'kangal' and
        $cat eq 'bengal' and
        ref($goat) eq 'ARRAY' and
        $goat->[0] eq 'kinder' and
        $goat->[1] eq 'angora'),
      join("\n",
           diff('kangal',$dog),
           diff('bengal',$cat),
           diff('kinder',$goat->[0]),
           diff('angora',$goat->[1]),
           undef));
;;;;;
my $dog;
my $cat;
my $goat;
eval {
  $dog = $main::config->dog;
  $cat = $main::config->cat;
  $goat = $main::config->goat;
};

check('The expected data was retrieved via the methodcall access method from the configuration file.',
      !($dog eq 'kangal' and
        $cat eq 'bengal' and
        ref($goat) eq 'ARRAY' and
        $goat->[0] eq 'kinder' and
        $goat->[1] eq 'angora'),
      join("\n",
           diff('kangal',$dog),
           diff('bengal',$cat),
           diff('kinder',$goat->[0]),
           diff('angora',$goat->[1]),
           undef));
;;;;;
eval {
  $main::config->reset();
};
check('reset() on a configuration object works.',
      ($@ or $main::config->get('dog') eq 'kangal'),
      $@);
;;;;;
$main::config->parse("/tmp/configtest.$$/catalog");
$main::config->read('test2');
use Date::Manip;
my $check = Date_Cmp(ParseDate('today'),ParseDate('today at 7:00 am'));
if ($check < 1) {
  $check = 'now';
} else {
  $check = 'later';
}

my $state = $main::config->get('start');
check('Conditional config evaluation seems to work.',
      $check ne $state,
      diff($check,$state));
;;;;;
$main::config->read('test2');
use Date::Manip;
my $check = Date_Cmp(ParseDate('today'),ParseDate('today at 7:00 am'));
if ($check < 1) {
  $check = 'now';
} else {
  $check = 'later';
}

my $state = $main::config->get('start');
check("Reading a config multiple times doesn't mess up the results.",
      $check ne $state,
      diff($check,$state));
ETESTS

runTests(@tests);
