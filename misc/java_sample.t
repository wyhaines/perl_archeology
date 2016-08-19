#!/usr/local/perl5.6.1/bin/perl
# Version: $Revision: 1.1.1.1 $
# Date Modified: $Date: 2001/12/17 02:28:37 $

#####
#// This just sets the CLASSPATH to be able to find some stuff that
#// will be used later.
#####
BEGIN {$ENV{CLASSPATH} .= '/opt/enigo/lib/cdcontent.jar'}

use strict;

use Enigo::TestTools qw(java);

print "Testing a Smattering of Java Things\n\n";

my @tests = split(/;;;;;/,<<'ETESTS');
#####
#// This first test just tries to get some system properties to
#// verify our operating environment.
#####
java(<<'END_OF_JAVA');
import java.lang.System;
import java.util.StringTokenizer;

class FirstTest {
  public FirstTest() { }

  // Return the Java version that we are using.
  public String getVersion() {
    return System.getProperty("java.version");
  }

  // Return an array of strings, each element of the array containing
  // a single piece of the version designation.
  public String[] getVersionBreakdown() {
    String version = System.getProperty("java.version");
    String major;
    String minor;
    String patch;
    StringTokenizer tokenizer = new StringTokenizer(version,".");

    major = (String)tokenizer.nextElement();
    minor = (String)tokenizer.nextElement();
    patch = (String)tokenizer.nextElement();

    return new String[] {major,minor,patch};
  }
}

END_OF_JAVA

#####
#// First, create an object.  Remember that, by default, all classes
#// defined in a java() call get subsumed under the Enigo::TestTools
#// namespace.
#####
my $FirstTest = new Enigo::TestTools::FirstTest;

#####
#// Call the first method to get the Java version.  Remember that in
#// Perl method invocations are indicated with an arrow '->'.
#####
my $version = $FirstTest->getVersion();

#####
#// Now get the three pieces of the version string, broken up.  The
#// interface between Perl and Java returns Java arrays as array
#// references in Perl.  To dereference an array reference, do this:
#//   @{REFERENCE}
#// So if $foo->bar is returning a Java array, you make it a Perl
#// array like so:
#//   @{$foo->bar}
#// So, what we do next is get a Java array of the breakdown of the
#// version, and then assign each successive element of that array to
#// a seperate variable.  If you can master this much Perl, you have
#// a big enough toolchest to write most tests that you could want.
#####
my ($major,$minor,$patch) = @{$FirstTest->getVersionBreakdown()};

#####
#// Now just test our results.
#####
check("We can get the Java version ($version), and it's not an ancient version (less than 1.2.0).",
      (($major < 1) or
       (($major == 1) and ($minor < 2)) or
       !$version));
;;;;;
#####
#// The second test illustrates the persistence of these test classes
#// from one Perl test block to another.  Within Perl, everything after
#// those five semicolons is running in a different scope than the code
#// in the previous block.  Within Java, though, it's all the same JVM,
#// so the class that we defined in the last block is still available.
#####
my $version2 = Enigo::TestTools::FirstTest->new()->getVersion();

check("The class that fetches the version ($version2) can still be called even though we are in a new block.",
      !$version2);
;;;;;
#####
#// So, it follows that we can create a Java class that exposes some
#// behavior that we want to throw a lot of data at, to see what happens.
#####
java(<<'END_OF_JAVA');
class TestAdd {
  public TestAdd() { }

  public int add(int arg1, int arg2) {
    return arg1 + arg2;
  }
}

END_OF_JAVA

my $result = callMethod('TestAdd','add',[1,1],1);
print "1+1 == $result\n";
check("Boilerplate invocation #1",
      !$result);
;;;;;
my $result = callMethod('TestAdd','add',[2,4],1);
print "2+4 == $result\n";
check("Boilerplate invocation #2",
      !$result);
;;;;;
my $result = callMethod('TestAdd','add',[6,12],1);
print "6+12 == $result\n";
check("Boilerplate invocation #3",
      !$result);
;;;;;
my $result = callMethod('TestAdd','add',[18,37],1);
print "18+37 == $result\n";
check("Boilerplate invocation #4",
      !$result);
;;;;;
my $result = callMethod('TestAdd','add',[2534532,998324525],1);
print "2534532+998324525 == $result\n";
check("Boilerplate invocation #5",
      !$result);
;;;;;
#####
#// Now lets try something a little more exciting.  Let's try to grab
#// a real, existing piece of the Enigo corpus and run some tests
#// against it.
#####
java(<<'END_OF_JAVA');
import enigo.cdcontent.ParseBuffer;

class PBtest {
  public PBtest() { }

  public ParseBuffer getPB(String thing) {
    return new ParseBuffer(thing);
  }
}

END_OF_JAVA

eval {
my $pb = Enigo::TestTools::PBtest->new()->getPB('12345');
};

check("A ParseBuffer can be created without error.",
      $@,
      $@);
;;;;;
my $pb = Enigo::TestTools::PBtest->new()->getPB('12345');
my $size = $pb->size();

check("A ParseBuffer correctly reports the size of its string ($size; should be 5).",
      ($size != 5),
      diff($size,5));
;;;;;
my $string = 'This is a test of ParseBuffer.';
my $pb = Enigo::TestTools::PBtest->new()->getPB($string);
my $position = $pb->indexOf('test');

check("The single argument indexOf() call works.",
      ($position != 10),
      "The string was: \'$string\'\nSearched for 'test'.\nGot position $position.\n");
;;;;;
my $string = 'This is a test of ParseBuffer.';
my $pb = Enigo::TestTools::PBtest->new()->getPB($string);
my $position = $pb->indexOf('ParseBuffer',10);

check("The single argument indexOf() call works.",
      ($position != 18),
      "The string was: \'$string\'\nSearched for 'ParseBuffer'.\nGot position $position.\n");
;;;;;
my $string = 'This is a test of ParseBuffer.';
my $pb = Enigo::TestTools::PBtest->new()->getPB($string);

check("ParseBuffer.toString() works.",
      ($pb->toString() ne $string),
      diff($string,$pb->toString()));
ETESTS
    

#####
#// Here's the main test loop.
#####
runTests(@tests);
