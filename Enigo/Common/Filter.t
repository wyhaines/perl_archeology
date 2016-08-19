#!/usr/bin/perl
#Version: $Revision: 1.1.1.1 $
#Date Modified: $Date: 2001/12/17 02:28:37 $

use strict;

use Enigo::TestTools qw(perl);

print "Testing Enigo::Common::Filter\n\n";

runTests(<<'ETESTS');
use Enigo::Common::Filter qw(test);
my $code;
my $base_code = $code = <<ECODE;
print "This is a test.\n";
print "This is only a test.\n";
ECODE
eval {
  $code = Enigo::Common::Filter->filter($code);
};

check("Filtering text that doesn't activate any filters works.",
      ($code ne $base_code),
      diff($code,$base_code));
;;;;;
my $code;
my $base_code = $code = <<'ECODE';
initialize($data);
ECODE
eval {
  $code = Enigo::Common::Filter->filter($code);
};

check("Filtering seems to work as expected.",
      ($code !~ /my \$self/s),
      $code);
ETESTS
