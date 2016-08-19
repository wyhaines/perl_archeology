#!/usr/bin/perl
#Version: $Revision: 1.1.1.1 $
#Date Modified: $Date: 2001/12/17 02:28:37 $

use strict;

use Enigo::TestTools qw(perl);
use Enigo::Common::Crypt;
use MIME::Base64;
use IO::Scalar;

print "Testing Enigo::Common::Crypt\n\n";

use vars qw($cipher $blowfish_key $plaintext $ciphertext);
$main::plaintext = "`n+1' trivial tasks take twice as long as `n' trivial tasks.";

runTests(<<'ETESTS');
my $key;
eval
  {
    $key = Enigo::Common::Crypt::generateKey(728,1);
  };
check("generateKey() can generate a random key of a given bit length:\n" .
      Text::Wrap::wrap('    ','',unpack('H182',$key)),
      !(length($key) == 91),
      $key);
;;;;;
my $key;
print "Generating a DES random key (this may take a while)....\n";
eval
  {
    $key = Enigo::Common::Crypt::randomKey('DES');
  };
check("randomKey() generates appropriate key for DES:\n" .
      Text::Wrap::wrap('    ','',unpack('H16',$key)),
      !(length($key) == 8),
      $key);
;;;;;
my $key;
print "Generating an IDEA random key (this may take a while)....\n";
eval
  {
    $key = Enigo::Common::Crypt::randomKey('IDEA');
  };
check("randomKey() generates appropriate key for IDEA:\n" .
      Text::Wrap::wrap('    ','',unpack('H32',$key)),
      !(length($key) == 16),
      $key);
;;;;;
my $key;
print "Generating a TripleDES random key (this may take a while)....\n";
eval
  {
    $key = Enigo::Common::Crypt::randomKey('TripleDES');
  };
check("randomKey() generates appropriate key for TripleDES:\n" .
      Text::Wrap::wrap('    ','',unpack('H96',$key)),
      !(length($key) == 48),
      $key);
;;;;;
print "Generating a Blowfish random key (this may take a while)....\n";
eval
  {
    $main::blowfish_key = Enigo::Common::Crypt::randomKey('Blowfish');
  };
check("randomKey() generates appropriate key for Blowfish:\n" .
      Text::Wrap::wrap('    ','',unpack('H112',$main::blowfish_key)),
      !(length($main::blowfish_key) == 56),
      $main::blowfish_key);
;;;;;
eval
  {
    $main::cipher = Enigo::Common::Crypt->new({KEY => $main::blowfish_key,
                                      CIPHER => 'Blowfish'}); 
  };
check('Enigo::Common::Crypt object can be created.',
      $@,
      $@);
;;;;;
check('key() returns the cryptographic key as expected.',
      !($main::cipher->key() eq $main::blowfish_key),
      diff($main::cipher->key(),$main::blowfish_key));
;;;;;
eval
  {
    $main::ciphertext = main::encode_base64($main::cipher->encrypt($main::plaintext));
  };
check("encrypt() works:\n$main::plaintext\n  becomes\n$main::ciphertext",
      $@,
      $@);
;;;;;
my $pt;
eval
  {
    $pt = $main::cipher->decrypt(main::decode_base64($main::ciphertext));
  };
check("decrypt() works:\n$main::ciphertext\n  becomes\n$main::plaintext",
      ($@ or ($pt ne $main::plaintext)),
      "$@" . diff($main::plaintext,$pt));
ETESTS

#runTests(@tests);
