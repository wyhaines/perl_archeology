#!/usr/bin/perl -wc
#
######################################################################
##### Header
######################################################################

=pod

=head1 NAME: $RCSfile: TestTools.pm,v $

Z<>

I<REVISION: $Revision: 1.1.1.1 $>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: $Date: 2001/12/17 02:28:37 $>

=head1 PURPOSE:

Provides a set of common subroutines to power automated test suites.

=head1 EXAMPLES:

  use Enigo::TestTools qw(java);

  my $testdir = writeDir("/tmp/test.foo.$$");
  $testdir->writeFile("/tmp/test.foo.$$/config",$config);
  java(<<'EOJ');
  //Java code.
  EOJ


=head1 TODO:

  -Fill out the internal documentation more completely.
  -Write a test suite to test each of the supported functions and languages.
  -Comment the code a little better.

Z<>

Z<>

Z<>

=head1 DESCRIPTION:

=cut

######################################################################
######################################################################

package Enigo::TestTools;

use strict;
use vars qw($VERSION @ISA @EXPORT_OK);

use Exporter;
@ISA = qw(Exporter);

@EXPORT_OK = qw(diff writeFile writeDir runTests java callMethod);

($VERSION) =
  '$Revision: 1.1.1.1 $' =~ /\$Revision:\s+([^\s]+)/;#';


use Algorithm::Diff;
use Text::Wrap;
use Term::ANSIColor;
use Cwd;

use Enigo::Common::IO::TempFile;
use Enigo::Common::IO::TempDir;


######################################################################
##### Method: import
######################################################################

=pod

=head2 METHOD_NAME: import

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 18 Oct 2001>

=over 4

=item PURPOSE:

Populates the calling namespace with the requested items, and
does the setup work to prepare for the testing of code for the
specified language.

=item ARGUMENTS:

A list containing a single scalar, the language that the code to
be tested is written in.  The currently supported values are:

  perl
  java
  C

Z<>

=item THROWS:

nothing

=item RETURNS:

undef

=item EXAMPLE:

  use TestTools qw(perl);

Z<>

=item TODO:

  -Clean up the documentation a bit.
  -Add the ability to look for POD or Javadoc and nag if it is
   not found?

=back

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub import {
  my $package = shift;

  my @symbols = @_;
  my @exporter_symbols = ();
  foreach (@symbols) {
  SWITCH: {
      /^perl$/i && do {
	#Nothing special.
	*Enigo::TestTools::_language_specific = sub {
	  #Really, nothing special.
	};
	push @exporter_symbols,qw(diff writeFile writeDir runTests);
	last SWITCH;
      };

      /^java$/i && do {
	#####
	#Java test environment setup.
	#####
	my $test_dir = cwd . "/.Inline_java_tests_$$";
	$Enigo::Common::TestTools::_Inline_dir =
	  Enigo::Common::IO::TempDir->new($test_dir);
	
	*Enigo::TestTools::_language_specific = sub {
	  unless ($ENV{PERL_INLINE_JAVA_BIN} or
		  scalar(grep {
		    grep {
		      m{javac} && (! -l $_)
		    } (glob "$_/*")
		  } (split(/:/,$ENV{PATH})))) {
	    die Text::Wrap::wrap('','',"Please specify the location of the java bin/ in the PERL_INLINE_JAVA_BIN environment variable and then run the test suite again.");
	  }
	  system("rm -rf $test_dir/\*");
	};

	eval <<'EUSEINLINE';
	use Inline Config =>
	  DIRECTORY => $test_dir;
EUSEINLINE

	push @exporter_symbols,qw(diff writeFile runTests java callMethod);
	*callMethod = \&_call_java_method;
	last SWITCH;
      };

      push @exporter_symbols,$_;
    }
  }

  $package->export_to_level(1,@exporter_symbols);
  undef;
}


######################################################################
##### Subroutine: makeRange
######################################################################

=pod

=head2 SUBROUTINE_NAME: makeRange

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 18 Oct 2001>

=over 4

=item PURPOSE:

Takes a list and generates a description of which elements of the
list are true, specifying any sequence of three or more consequtive
true elements as a range.  This routine is used by TestTools to report
on the tests that passed/failed.

=item ARGUMENTS:

A list to analyze.

=item THROWS:

nothing

=item RETURNS:

If called in an array context, returns an array containing one
element for each seperate piece of the description.

If called in a scalar context, returns the description as a single
string.

=item EXAMPLE:

  @range = makeRange(@list);
  $range = makeRange(@list);
  #$range eq join(',',makeRange(@list))

Z<>

=item TODO:

=back

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub makeRange {
  my @list = @_;

  my @minirange;
  my @range;

  for my $item (sort {$a <=> $b} @list) {
    if (scalar @minirange) {
      my $should_be_next = $minirange[$#minirange] + 1;
      if ($should_be_next == $item) {
	push @minirange,$item;
      } else {
	if (scalar(@minirange) < 3) {
	  push @range,@minirange;
	  @minirange = ($item);
	} else {
	  push @range,join('-',
			   $minirange[0],
			   $minirange[$#minirange]);
	  @minirange = ($item);
	}
      }
    } else {
      @minirange = ($item);
    }
  }

  if (scalar @minirange) {
    if (scalar(@minirange) < 3) {
      push @range,@minirange;
      @minirange = ();
    } else {
      push @range,join('-',
		       $minirange[0],
		       $minirange[$#minirange]);
      @minirange = ();
    }
  }

  return wantarray ? @range : join(',',@range);
}


sub runTests {
  use vars qw($test_num);
  my @tests;
  if (scalar(@_) > 1) {
    @tests = @_;
  } else {
    @tests = split(/;;;;;/,$_[0]);
  }

  @Enigo::TestTools::checklist = ();
  @Enigo::TestTools::summary = ();
  #Here's the main test loop.
  print "1..",scalar(@tests),"\n";
  local $test_num;

  foreach my $test (@tests)
    {
      $test_num++;
      Enigo::TestTools::_language_specific();
      eval($test);
      if ($@ and !$Enigo::TestTools::checklist[$test_num])
        {
	  $Enigo::TestTools::summary[$test_num] = 0;
          print "FATAL ERROR\n";
          my $err = "$@\n" if $@;
          $err .= "$!\n" if $!;
          print "$err\nnot ok $test_num\n";
        }
    }

  print "\nSummary:\n";
  my @ok_range = grep {$_} @Enigo::TestTools::summary;
  my @not_ok_range;
  for (my $k = 1;$k <= $#Enigo::TestTools::summary;$k++) {
    push @not_ok_range,$k unless $Enigo::TestTools::summary[$k];
  }
  my $ok_range = makeRange(@ok_range);
  my $not_ok_range = scalar @not_ok_range ?
    join('',
	 color('bold'),
	 scalar(makeRange(@not_ok_range)),
	 color('reset')) : undef;
  print "  Tests that passed:\n",Text::Wrap::wrap('    ','    ',$ok_range),"\n\n";
  print "  Tests that failed:\n",Text::Wrap::wrap('    ','    ',$not_ok_range),"\n\n";
  print '-' x 65,"\n\n";

  sub check {
    my $description = shift;
    my $rc = shift;
    my $failure_information = shift;
    $Enigo::TestTools::checklist[$test_num]++;
    print Text::Wrap::wrap('','    ',"* $description\n");
    unless ($rc) {
      print "ok $test_num\n\n";
      $Enigo::TestTools::summary[$test_num] = $test_num;
    } else {
      $Enigo::TestTools::summary[$test_num] = 0;
      if (defined $failure_information)
	{
	  print <<ETXT;
*****************************
    Failed test returned:
$failure_information
*****************************
ETXT
	}
      print "not ok $test_num\n\n";
    }
  }
}


sub java {
  my $code = shift;

  Inline->bind(Java => $code,
	       AUTOSTUDY => 1,
	       NAME => "a$$");

}

sub _call_java_method {
  my ($class,$method,$args,$persistent) = @_;

  $args = [] unless $args;

  #####
  #// If $class actually contains an object...
  #####
  if (ref $class) {
    #####
    #// If the persistence flag is set, save this object.
    #####
    if ($persistent) {
      $Enigo::TestTools::__persistent_objects__{ref $class} = $class;
    }
    #####
    #// Invoke the method.
    #####
    return $class->$method(@{$args});
  #####
  #// Otherwise...
  #####
  } else {
    #####
    #// If the persistence flag is set and we already have a saved object
    #####
    if ($persistent and
        exists $Enigo::TestTools::__persistent_objects__{$class}) {
      #####
      #// Invoke the method on that saved object.
      #####
      return $Enigo::TestTools::__persistent_objects__{$class}->
        $method(@{$args});
    #####
    #// Otherwise craft a new object.
    #####
    } else {
      my $full_class = "Enigo::TestTools::$class";
      my $object = $full_class->new();
      #####
      #// And save the new object if we want persistence.
      #####
      $Enigo::TestTools::__persistent_objects__{$class} = $object
        if $persistent;
      #####
      #// Then invoke the method.
      #####
      return $object->$method(@{$args});
    }
  }
}


######################################################################
##### Subroutine: diff
######################################################################

=pod

=head2 SUBROUTINE_NAME: diff

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 18 Oct 2001>

=over 4

=item PURPOSE:

Produces a diff between the two input arguments.

=item ARGUMENTS:

Two scalar values to be compared.

=item THROWS:

nothing

=item RETURNS:

A scalar containing the diff between the two input arguments.

=item EXAMPLE:

  print diff($a,$b);

Z<>

=item TODO:

=back

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub diff {
  my $s1 = [split(/\n/,shift)];
  my $s2 = [split(/\n/,shift)];

  #####
  #Algorithm::Diff handles the hard work
  #####
  my $diffs = Algorithm::Diff::diff($s1,$s2);
  my $result;

  foreach my $chunk (@{$diffs}) {
    foreach my $line (@{$chunk}) {
      my ($sign, $lineno, $text) = @{$line};
      $result .= sprintf "%4d$sign %s\n", $lineno+1, $text;
    }
    $result .= "--------\n";
  }

  return $result;
}


######################################################################
##### Subroutine: writeDir
######################################################################

=pod

=head2 SUBROUTINE_NAME: writeDir

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 09 Nov 2001>

=over 4

=item PURPOSE:

wrietDir() will create a temporary directory (an instance of
L<Enigo::Common::IO::TempDir|Enigo::Common::IO::TempDir>) and return the
object representing that directory.  This object is a subclass of
L<IO::Dir|IO::Dir> and can be used in the same way.  See the
documentation on L<Enigo::Common::IO::TempDir|Enigo::Common::IO::TempDir>
and L<IO::Dir|IO::Dir> for more information.

=item ARGUMENTS:

Takes a single scalar argument, the path of the directory to
create.

=item THROWS:

nothing

=item RETURNS:

A L<Enigo::Common::IO::TempDir|Enigo::Common::IO::TempDir> object.

=item EXAMPLE:

  my $dh = Enigo::TestTools::writeDir("/tmp/frobitzmadir.$$");

Z<>

=item TODO:

=back

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub writeDir {
  return Enigo::Common::IO::TempDir->new(@_);
}


######################################################################
##### Subroutine: writeFile
######################################################################

=pod

=head2 SUBROUTINE_NAME: writeFile

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 18 Oct 2001>

=over 4

=item PURPOSE:

Provides a simple call to write a file that will contain some
arbitrary content.  If the file already exists, it will be
overwritten.  If the filename does not exist or is the empty
string, a random name will be created.  A usable filehandle
(actually an instance of L<Enigo::Common::IO::TempFile|Enigo::Common::IO::TempFile>,
which is a subclass of L<IO::File|IO::File>) for the file is
created.  All files created with writeFile are temporary files,
and will go away when their filehandle goes out of scope.

=item ARGUMENTS:

The call will accept one, two, or three arguments.  The first
argument is the path of the file to write, and is mandatory.

The second argument is the data to insert into the file.  If this
is omitted, the file will be empty.

The third argument is a L<Enigo::Common::IO::TempDir|Enigo::Common::IO::TempDir>
object, such as is returned from the writeDir() call.  If this is provided,
the file will be created within the context of that TempDir.
See the L<Enigo::Common::IO::TempDir|Enigo::Common::IO::TempDir> documentation
for more information on how this works.

=item THROWS:

nothing

=item RETURNS:

A filehandle (a L<Enigo::Common::IO::TempFile|Enigo::Common::IO::TempFile> object).

=item EXAMPLE:

  my $fh = Enigo::TestTools::writeFile('/tmp/frobitzma',"testing\n");

Z<>

=item TODO:

=back

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub writeFile {
  my $path = shift;
  my $contents = shift;
  my $dir = shift;

  if (ref($dir) =~ /TempDir/) {
    return $dir->writeFile($path,$contents);
  } else {
    my $fh = Enigo::Common::IO::TempFile->new($path);
    $fh->print($contents);
    $fh->seek(0,0);

    return $fh;
  }
}


#If a test is doing something wierd (while you are developing the test script),
#and the test involves eval statements that you would like to step through in
#the debugger, put a call to breakpoint() in the eval statement at the point
#that you would like to start stepping through.  Then, when you go into the
#debugger, you can 'b breakpoint' and your code will break where you want it
#to.
sub breakpoint {print $main::fifi++,"\n";return $main::fifi;}

1;
