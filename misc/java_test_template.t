#!/usr/local/perl5.6.1/bin/perl
# Version: $Revision: 1.1.1.1 $
# Date Modified: $Date: 2001/12/17 02:28:37 $

use strict;

use Enigo::TestTools qw(java);

print "Testing THE_CLASS_TO_BE_TESTED\n\n";

#####
#// Declare any variables that your test code may want.  If you need to
#// create a persistent object in order to test a class, declare the
#// variable here.
#####

my @tests = split(/;;;;;/,<<'ETESTS');

#####
#// This is where you write your tests.  Do whatever you need to do to
#// test some single bit of functionality; if it's something that might
#// throw a fatal error, wrap it in an eval and then you can test the
#// $@ variable once the eval exits to see if bad things happened.
#// When you're ready to check a result, you'll have a line like this:
#// 
#// check('getCurrentSequenceNumber() works.',
#//       $sequencer->getCurrentSequenceNumber() != 100,
#//       diff($sequencer->getCurrentSequenceNumber(),100));
#// 
#// check() is provided by the Enigo::TestTools package.
#// It takes 2, or optionally 3 arguments.  The first is a textual
#// description of what is being tested.  The second is a statement
#// that will be evaluated for true/false.  If true, it indicates
#// that there was an error with the test -- the test failed.  Yeah,
#// true indicates failure, and false indicates success.  Confusing,
#// I know, but that's life**.  The third optional argument is diagnostic
#// output to provide if the test resulted in a failure.  This is a
#// scalar value which will be printed.  A useful routine provided in
#// this test script (that also really should be abstracted to an external
#// library) is diff().  If given two scalar arguments, it will return
#// a diff between the two.  Use this if you know exactly what your test
#// was supposed to return, and you want to show the difference between
#// what was expected, and what was actually received.
#// 
#// **The actual reason for true indicating a failure has to do with
#//   how errors are trapped in an eval() statement.  Any code that
#//   is executed within an eval() statement is buffered, with regard
#//   to fatal errors, from the rest of the code.  The error gets
#//   captured in a special variable, $@.  Thus, in a check() call,
#//   if $@ is used as the check condition, it is a failure if there
#//   is anything in $@ as that indicates that some sort of fatal error
#//   occured.  This was the original reasoning, anyway, and there are
#//   so many test scripts written to this behavior now that changing
#//   it would just be confusing.
#//
#// The individual tests are then seperated with five semicolons on a
#// line by themselves:
#####
;;;;;
#####
#// This would then start the body of the second test.
#####
;;;;;
#####
#// And this would be the third, and so on.
#####
ETESTS
    

#####
#// Here's the main test loop.
#####
runTests(@tests);
