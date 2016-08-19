#!/usr/bin/perl

use strict;

use Enigo::Common::Override {exit => ['Enigo::Common::Exception']};
use THE_MODULE_TO_TEST;  #Gotta use whatever you plan to test, ya know.
use IO::Scalar;
use Algorithm::Diff;
use Text::Wrap;
use Error qw(:try);

print "Testing THE_MODULE_TO_TEST\n\n";

#Declare any variables that your test code may want.  If you need to
#create a persistent object in order to test an object class, declare
#the variable here, for example.

my @tests = split(/;;;;;/,<<'ETESTS');

#This is where you write your tests.  Do whatever you need to do to
#test some single bit of functionality; if it's something that might
#throw a fatal error, wrap it in an eval and then you can test the
#$@ variable once the eval exits to see if bad things happened.
#When you're ready to check a result, you'll have a line like this:
#
#check('getCurrentSequenceNumber() works.',
#      $sequencer->getCurrentSequenceNumber() != 100,
#      diff($sequencer->getCurrentSequenceNumber(),100));
#
#check() is implemented below, in this file (it should probably be
#abstracted into an external library since it's used in every
#test script).  It takes 2, or optionally 3 arguments.  The first
#is a textual description of what is being tested.  The second is
#a statement that will be evaluated for true/false.  If true, it
#indicates that there was an error with the test -- the test failed.
#Yeah, true indicates failure, and false indicates success.  Confusing,
#I know, but that's life.  The third, optional argument, is diagnostic
#output to provide if there was an error with the test.  This is a
#scalar value which will be printed.  A useful routine provided in
#this test script (that also really should be abstracted to an external
#library) is diff().  If given two scalar arguments, it will return
#a diff between the two.  Use this if you know exactly what your test
#was supposed to return, and you want to show the difference between
#what was expected, and what was actually received.
#
#The individual tests are then seperated with five semicolons on a
#line by themselves:
#
;;;;;
#This would then start the body of the second test.
;;;;;
#And this would be the third, and so on.
ETESTS
    

#Here's the main test loop.
print "1..",scalar(@tests),"\n";
my $test_num;

foreach my $test (@tests)
  {
    eval($test);
    if ($@ or $!)
      {
        $test_num++;
        print "FATAL ERROR\n";
        print "$@\nnot ok $test_num\n";
      }
  }

{
  $test_num = 0;
  sub check
    {
      my $description = shift;
      my $rc = shift;
      my $failure_information = shift;
      $test_num++;
      print Text::Wrap::wrap('','    ',"$description\n");
      unless ($rc)
        {
          print "ok $test_num\n";
        }
      else
        {
          if (defined $failure_information)
            {
              print <<ETXT;
*****************************
    Failed test returned:
$failure_information
*****************************
ETXT
            }
          print "not ok $test_num\n";
        }
    }
}


sub diff
  {
    my $s1 = [split(/\n/,shift)];
    my $s2 = [split(/\n/,shift)];

    my $diffs = Algorithm::Diff::diff($s1,$s2);
    my $result;

    foreach my $chunk (@{$diffs})
      {
        foreach my $line (@{$chunk})
          {
            my ($sign, $lineno, $text) = @{$line};
            $result .= sprintf "%4d$sign %s\n", $lineno+1, $text;
          }
        $result .= "--------\n";
      }

    return $result;
  }

#If a test is doing something wierd (while you are developing the test script),
#and the test involves eval statements that you would like to step through in
#the debugger, put a call to breakpoint() in the eval statement at the point
#that you would like to start stepping through.  Then, when you go into the
#debugger, you can 'b breakpoint' and your code will break where you want it
#to.
sub breakpoint {print $main::fifi++,"\n";return $main::fifi;}
