#!/usr/local/perl5.6.1/bin/perl
# Version: $Revision: 1.1.1.1 $
# Date Modified: $Date: 2001/12/17 02:28:37 $

use strict;
use IO::Scalar;
use Log::Dispatch;
use Log::Dispatch::File;

use Enigo::TestTools qw(perl);

my $filename = 'debug.pm';
open(FILE,"<$filename") or
  die "The test suite must be executed from the dir that contains $filename.";
my $code = join('',<FILE>);
close FILE;

eval $code;

print "Testing debug() function in $filename\n\n";

#####
#// First of all, we need to setup the stuff that debug() needs, including
#// a Log::Dispatch object.  We'll setup a temporary logging location to
#// capture the logs so that their contents can be verified.
#####
$main::tmpdir = writeDir("/tmp/test.debug.$$");
$main::tmpfile = $main::tmpdir->writeFile("+>/tmp/test.debug.$$/tmplog","START\n");

$Enigo::Products::RPCServer::Server::Dispatcher = Log::Dispatch->new();
$Enigo::Products::RPCServer::Server::Dispatcher->add
  (Log::Dispatch::File->new(name => 'log',
			    filename => "/tmp/test.debug.$$/tmplog",
			    min_level => 0));

%main::CLVAR = (debug => 'tmp:0');

my @tests = split(/;;;;;/,<<'ETESTS');

eval {
  main::debug({MESSAGE => "This is debugging message #0.\n"});
};
check("debug() called without a CLVAR is an error.",
      !$@);
;;;;;
eval {
  main::debug({CLVAR => \%main::CLVAR,
               MESSAGE => "This is debugging message #1.\n"});
};
check("debug() called in a vanilla configuration without error.",
      $@,
      $@);
;;;;;
my $log;
eval {
  main::debug({ID => 'tmppppp',
               CLVAR => \%main::CLVAR,
               MESSAGE => "This is debugging message #2.\n"});
};
$main::tmpfile->seek(0,0);
while (my $line = $main::tmpfile->getline) {
  $log = $line if $line =~ m{message #2};
}

check("Calling debug() with an incorrect ID will not log.",
      $log);
;;;;;
my $log;
eval {
  main::debug({ID => 'tmp',
               CLVAR => \%main::CLVAR,
               MESSAGE => "This is debugging message #3.\n"});
};
$main::tmpfile->seek(0,0);
while (my $line = $main::tmpfile->getline) {
  $log = $line if $line =~ m{message #3};
}

check("Calling debug() with a correct ID logs correctly.",
      !$log);
;;;;;
my $log;
eval {
  main::debug({ID => 'frumpybad',
               CLVAR => \%main::CLVAR,
               MESSAGE => "This is debugging message #4.\n"});
};
$main::tmpfile->seek(0,0);
while (my $line = $main::tmpfile->getline) {
  $log = $line if $line =~ m{message #4};
}

check("Calling debug() without a correct ID doesn't log.",
      $log);
;;;;;
my $log;
local %main::CLVAR = (debug => 'tmp:1');
eval {
  main::debug({ID => 'frumpybad',
               CLVAR => \%main::CLVAR,
               MESSAGE => "This is debugging message #5.\n"});
};
$main::tmpfile->seek(0,0);
while (my $line = $main::tmpfile->getline) {
  $log = $line if $line =~ m{message #5};
}

check("Calling debug() with a loglevel that is too low doesn't log.",
      $log);
;;;;;
my $stderr;
tie(*STDERR,'IO::Scalar');
eval {
  main::debug({ID => 'tmp',
               LOG => 0,
               CLVAR => \%main::CLVAR,
               MESSAGE => "This is debugging message #6.\n"});
};

tied(*STDERR)->seek(0,0);
$stderr = join('',(tied(*STDERR)->getlines()));
untie *STDERR;
print STDERR $stderr;

check("Calling debug() with a LOG => 0 still properly defaults to a message going to STDERR.",
      !$stderr);
;;;;;
my $log;
eval {
  main::debug({ID => 'tmp',
               LOG => 0,
               CLVAR => \%main::CLVAR,
               MESSAGE => "This is debugging message #7.\n"});
};

$main::tmpfile->seek(0,0);
while (my $line = $main::tmpfile->getline) {
  $log = $line if $line =~ m{message #7};
}

check("Calling debug() with a LOG => 0 does not result in a message going to the Dispatcher.",
      $log,
      diff('',$log));
ETESTS
    

#####
#// Here's the main test loop.
#####
runTests(@tests);
