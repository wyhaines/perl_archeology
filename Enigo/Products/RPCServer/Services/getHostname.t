#!/usr/local/perl5.6.1/bin/perl
# Version: $Revision: 1.1.1.1 $
# Date Modified: $Date: 2001/12/17 02:28:37 $

use strict;

use Enigo::TestTools qw(perl);

my $filename = 'getHostname.pm';
open(FILE,"<$filename") or
  die "The test suite must be executed from the dir that contains $filename.";
my $code = join('',<FILE>);
close FILE;

eval $code;

print "Testing getHostname() function in $filename.\n\n";

my @tests = split(/;;;;;/,<<'ETESTS');
my $hostname;
eval {
  $hostname = main::getHostname();
};
check("getHostname() executes without error and reports the hostname as '$hostname'.",
     $@,
     $@);

ETESTS
    

#####
#// Here's the main test loop.
#####
runTests(@tests);
