#!/usr/bin/perl
#Version: $Revision: 1.1.1.1 $
#Date Modified: $Date: 2001/12/17 02:28:37 $

use strict;

use Enigo::TestTools qw(perl);
use Enigo::Common::MethodHash;

print "Testing Enigo::Common::MethodHash\n\n";

use vars qw($mhrf);

runTests(<<'ETESTS');
$main::mhrf = Enigo::Common::MethodHash->new();

check("Basic object creation works via class constructor works.",
      (ref($main::mhrf) ne 'Enigo::Common::MethodHash'),
      diff(ref($main::mhrf),'Enigo::Common::MethodHash'));
;;;;;
my $mhrf2 = $main::mhrf->new();

check("Basic object creation works via object constructor works.",
      (ref($mhrf2) ne 'Enigo::Common::MethodHash'),
      diff(ref($mhrf2),'Enigo::Common::MethodHash'));
;;;;;
eval {
  print "Setting:\n";
  print "    scalarval => 'I am a scalar value.'\n";
  $main::mhrf->scalarval('I am a scalar value.');
};

check("Scalar assignment via a method doesn't throw any errors.",
      $@,
      $@);
;;;;;
print "Getting scalarval via \$main::mhrf->{scalarval}:\n";
my $value = $main::mhrf->{scalarval};
print "    $value\n";

check("Retrieving a scalar value via regular hashref syntax works.\n",
      $value ne 'I am a scalar value.',
       diff($value,'I am a scalar value.'));
;;;;;
print "Getting scalarval via \$main::mhrf->scalarval:\n";
my $value = $main::mhrf->scalarval;
print "    $value\n";

check("Retrieving a scalar value via the method syntax works.\n",
      $value ne 'I am a scalar value.',
       diff($value,'I am a scalar value.'));
;;;;;
eval {
  print "Setting:\n";
  print "    arrayval => (1,2,3,4,5)\n";
  $main::mhrf->arrayval(1,2,3,4,5);
};

check("Assignment of an array of values via a method doesn't throw any errors.",
      $@,
      $@);
;;;;;
print "Getting arrayval via \$main::mhrf->{arrayval}:\n";
my $value = join(',',@{$main::mhrf->{arrayval}});
print "    $value\n";

check("Retrieving an arrayref value via regular hashref syntax works.\n",
      $value ne '1,2,3,4,5',
       diff($value,'1,2,3,4,5'));
;;;;;
print "Getting arrayval via \$main::mhrf->arrayval:\n";
my $value = join(',',@{$main::mhrf->arrayval});
print "    $value\n";

check("Retrieving an arrayref value via the method syntax works.\n",
      $value ne '1,2,3,4,5',
       diff($value,'1,2,3,4,5'));
;;;;;
eval {
  print "Setting\n";
  print "    top_floor => 3\n";
  print "    middle_floor => 2\n";
  print "    bottom_floor => 1\n";
  $main::mhrf->top_floor(3)
       ->middle_floor(2)
       ->bottom_floor(1);
};

check("Stacked assignments don't throw any errors.",
      $@,
      $@);
;;;;;
print "Getting top_floor, middle_floor, and bottom_floor:\n";
my $top = $main::mhrf->top_floor;
my $middle = $main::mhrf->middle_floor;
my $bottom = $main::mhrf->bottom_floor;
print "    top_floor == $top\n";
print "    middle_floor == $middle\n";
print "    bottom_floor == $bottom\n";

check("Stacked assignments work.",
      (($top != 3) or ($middle != 2) or ($bottom != 1)));
ETESTS
