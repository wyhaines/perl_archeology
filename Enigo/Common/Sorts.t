#!/usr/local/perl5.6.1/bin/perl

use Enigo::TestTools qw(perl);
use Enigo::Common::Sorts;

print "Testing Enigo::Common::Sorts\n\n";

my @tests = split(/;;;;;/,<<'ETESTS');

my %hash = (a => 'z',
            b => 'm',
	    c => 'a');

my @sorted = Enigo::Common::Sorts::sortHashByStringValue(\%hash);
my $string = join('',@sorted);

check("sortHashByStringValue() works.",
      ($string ne 'cba'),
      "The order received is this: \n" .
      join("\n",@sorted) .
      "\n\nThe diff between the expected order and the actual order is:\n" .
      diff("c\nb\na",join("\n",@sorted)));
;;;;;
my %hash = (a => '02',
            b => '3',
	    c => '001');

my @sorted = Enigo::Common::Sorts::sortHashByNumericValue(\%hash);
my $string = join('',@sorted);

check("sortHashByNumericValue() works.",
      ($string ne 'cab'),
      "The order received is this: \n" .
      join("\n",@sorted) .
      "\n\nThe diff between the expected order and the actual order is:\n" .
      diff("c\na\nb",join("\n",@sorted)));
;;;;;
my %hash = (a => {COLOR => 'puce',
                  VOTES => 17},
            b => {COLOR => 'vermillion',
                  VOTES => 49},
	    c => {COLOR => 'olive drab',
                  VOTES => 18});

my @sorted = Enigo::Common::Sorts::sortHashByHRStringValue(\%hash,'COLOR');
my $string = join('',@sorted);

check("sortHashByHRStringValue() works.",
      ($string ne 'cab'),
      "The order received is this: \n" .
      join("\n",@sorted) .
      "\n\nThe diff between the expected order and the actual order is:\n" .
      diff("c\na\nb",join("\n",@sorted)));
;;;;;
my %hash = (a => {COLOR => 'puce',
                  VOTES => 49},
            b => {COLOR => 'vermillion',
                  VOTES => 17},
	    c => {COLOR => 'olive drab',
                  VOTES => 18});

my @sorted = Enigo::Common::Sorts::sortHashByHRNumericValue(\%hash,'VOTES');
my $string = join('',@sorted);

check("sortHashByHRNumericValue() works.",
      ($string ne 'bca'),
      "The order received is this: \n" .
      join("\n",@sorted) .
      "\n\nThe diff between the expected order and the actual order is:\n" .
      diff("b\nc\na",join("\n",@sorted)));

ETESTS

runTests(@tests);
