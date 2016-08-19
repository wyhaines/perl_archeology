#!/home/khaines/bin/perl
#Revision: $Revision: 1.1.1.1 $
#Date Modified: $Date: 2001/12/17 02:28:37 $

use strict;

use Enigo::Common::IO::TempDir;
use Enigo::TestTools qw(perl);
use Digest::MD5 qw(md5_hex);

$! = '';
print "Testing Enigo::Common::IO::TempDir\n\n";

runTests(<<'ETESTS');
eval {
  my $tmpdir = Enigo::Common::IO::TempDir->new("/tmp/TempDir.1.test.$$");
};

check("A new tempdir can be created without runtime errors.",
      $@,
      $@);
;;;;;
my $test_case;
eval {
  my $tmpdir = Enigo::Common::IO::TempDir->new("/tmp/TempDir.2.test.$$");
  $test_case = (-e "/tmp/TempDir.2.test.$$");
};

check("The tempdir is successfully created on the filesystem.",
      !$test_case);
;;;;;
my $test_case;
eval {
  my $tmpdir = Enigo::Common::IO::TempDir->new("/tmp/TempDir.3.test.$$");
  $test_case = ref($tmpdir);
};

check("The new() method returned a proper object/dirhand.",
      ($test_case ne 'Enigo::Common::IO::TempDir'),
      diff('Enigo::Common::IO::TempDir',$test_case));
;;;;;

eval {
  $main::persistent_dir = Enigo::Common::IO::TempDir->new("/tmp/TempDir.4.test.$$");
  $main::persistent_dir->open("/tmp/TempDir.4.test.$$/foo/bar");
  $main::persistent_dir->open("/tmp/TempDir.4.test.$$/foo/biz/baf");
  $main::persistent_dir->writeFile("+>/tmp/TempDir.4.test.$$/foo/bar/test.txt","test1\n");
  $main::persistent_dir->writeFile("/tmp/TempDir.4.test.$$/foo/biz/baf/test2.txt","test2\n");
};

check("A complex directory structure with multiple directories and files was created without errors.",
      $@,
      $@);
;;;;;
check("All of the directories and files exist as they should.",
      !(-e "/tmp/TempDir.4.test.$$/foo/bar" and
        -e "/tmp/TempDir.4.test.$$/foo/biz/baf" and
        -e "/tmp/TempDir.4.test.$$/foo/bar/test.txt" and
        -e "/tmp/TempDir.4.test.$$/foo/biz/baf/test2.txt"));
;;;;;
eval {
  $main::persistent_dir->unlink("/tmp/TempDir.4.test.$$/foo/biz/baf");
};

check("unlink() was invoked on a directory structure without errors.",
      ($@ or (-e "/tmp/TempDir.4.test.$$/foo/biz/baf")),
      $@ ? $@ : (-e "/tmp/TempDir.4.test.$$/foo/biz/baf") ?
        "/tmp/TempDir.4.test.$$/foo/biz/baf still exists" :
        "Unknown error -- you shouldn't be seeing this.");
;;;;;
undef $main::persistent_dir;

check("Removing the top level directory correctly removes everything remaining underneath it.",
      (-e "/tmp/TempDir.4.test.$$"),
      "/tmp/TempDir.4.test.$$ still exists");

ETESTS

