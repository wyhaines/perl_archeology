#!/home/khaines/bin/perl
#Revision: $Revision: 1.1.1.1 $
#Date Modified: $Date: 2001/12/17 02:28:37 $

use strict;

use Enigo::Common::IO::TempFile;
use Enigo::TestTools qw(perl);
use Digest::MD5 qw(md5_hex);

$! = '';
print "Testing Enigo::Common::IO::TempFile\n\n";

runTests(<<'ETESTS');
eval {
  my $tmpfile = Enigo::Common::IO::TempFile->new(">/tmp/TempFile.1.test.$$");
};

check("A new tempfile can be created without runtime errors.",
      $@,
      $@);
;;;;;
my $test_case;
eval {
  my $tmpfile = Enigo::Common::IO::TempFile->new(">/tmp/TempFile.2.test.$$");
  $test_case = (-e "/tmp/TempFile.2.test.$$");
};

check("The tempfile is successfully created on the filesystem.",
      !$test_case);
;;;;;
my $test_case;
eval {
  my $tmpfile = Enigo::Common::IO::TempFile->new(">/tmp/TempFile.3.test.$$");
  $test_case = ref($tmpfile);
};

check("The new() method returned a proper object/filehand.",
      ($test_case ne 'Enigo::Common::IO::TempFile'),
      diff('Enigo::Common::IO::TempFile',$test_case));
;;;;;
my $original_data = <<ETXT;
This is a test.
This is only a test.
In the case of actual code, it would probably do something useful.
This is a test.
ETXT
my $original_digest = Digest::MD5::md5_hex($original_data);
my $test_case;
my $file_data;
eval {
  my $tmpfile = Enigo::Common::IO::TempFile->new("+>/tmp/TempFile.4.test.$$");
  print $tmpfile $original_data;
  $tmpfile->seek(0,0);
  $file_data = join('',$tmpfile->getlines);
  my $file_digest = Digest::MD5::md5_hex($file_data);
  $test_case = ($original_digest eq $file_digest);
};

check("Data can be written to, and retrieved from the temporary file accurately.",
      !$test_case,
      diff($original_data,$file_data));
ETESTS

