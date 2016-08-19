#!/usr/bin/perl -wc
#
######################################################################
##### Header
######################################################################
=pod

=head1 FILE_NAME: Crypt.pm

=head1 Enigo::Common::Crypt

I<REVISION:$Revision: 1.1.1.1 $>

I<AUTHOR: $Author: khaines $>

I<DATE_MODIFIED: $Date: 2001/12/17 02:28:37 $>

=head1 PURPOSE:

This is a wrapper around Crypt::CBC that implements an exception
throwing interface to cryptographic functions.

=head1 EXAMPLE:

  my $key = Enigo::Common::Crypt::randomKey('Blowfish');
  my $cipher = Enigo::Common::Crypt->new({KEY => $key,
                                       CIPHER => 'Blowfish'});
  my $plaintext = 'This is a test';
  my $ciphertext = $cipher->encrypt($plaintext);
  my $decrypted_plaintext = $ciphter->decrypt($ciphertext);

=head1 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

package Enigo::Common::Crypt;

use strict;

use Enigo::Common::Exception qw(:IO);
require Enigo::Common::Exception::Crypt::FailedInitialization;
require Enigo::Common::Exception::Crypt::EncryptFailed;
require Enigo::Common::Exception::Crypt::DecryptFailed;

use Crypt::CBC;
eval {
  require Crypt::Random;
};

if ($@) {
  $Enigo::Common::Crypt::has_Crypt_Random = 0;
} else {
  $Enigo::Common::Crypt::has_Crypt_Random = 1;
}
  
$Enigo::Common::Crypt::VERSION =
  '$Revision: 1.1.1.1 $ ' =~ /\$Revision:\s+([^\s]+)/;


######################################################################
##### Constructor: new
######################################################################

=pod

=head2 CONSTRUCTOR_NAME: new

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 30 Jun 2000>

=head2 PURPOSE:

Returns a hash ref blessed into Enigo::Common::Crypt.  This class is
implements the CBC::Crypt interface with exception support for
performing cryptographic functions.  It also has some useful helper
functions bundled into it.

=head2 ARGUMENTS:

Takes two scalar arguments.  The first is the cryptographic key
to use.  The second is the cryptographic cipher to use.  If
the key is omitted, a random key will be generated to the
maximum keysize of the cipher to be used.  This key can
be retrieved with the C<key()> method.  If the cipher is
omitted, the library will default to the Blowfish cipher
(see L<Crypt::Blowfish>).

The arguments may also be passed via a hash reference with the
keys of KEY and CIPHER.

=head2 RETURNS:

A hashref blessed into Enigo::Common::Crypt.

=head2 THROWS:

Enigo::Common::Exception::Crypt::FailedInitialization

=head2 EXAMPLE

my $crypt = Enigo::Common::Crypt->new($key,'IDEA');

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub new
  {
    my $proto = shift;
    my $self = {KEY => '',
        CIPHER => 'Blowfish'};

    if (ref($_[0]) eq 'HASH')
      {
    $self->{KEY} = $_[0]->{KEY};
    $self->{CIPHER} =
      $_[0]->{CIPHER} ? $_[0]->{CIPHER} : $self->{CIPHER};
      }
    else
      {
    $self->{KEY} = $_[0];
    $self->{CIPHER} =
      defined($_[1]) ? $_[1] : $self->{CIPHER};
      }

    bless($self,$proto);

    $self->{KEY} = $self->randomKey() unless $self->{KEY};

    eval
      {
    $self->{CRYPT_OBJECT} = Crypt::CBC->new($self->{KEY},
                        $self->{CIPHER});
      };
    throw Enigo::Common::Exception::Crypt::FailedInitialization
      ({CIPHER => $self->{CIPHER},
    KEY => $self->{KEY}}) if $@;

    return $self;
  }



sub blocksize {
  my $self = shift;

  return $self->{CRYPT_OBJECT}->{crypt}->blocksize();
}


######################################################################
##### Method: generateKey
######################################################################

=pod

=head2 METHOD_NAME: generateKey

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 06 Jun 2000>

=head2 PURPOSE:

Returns a random sequence of bits.  This routine can be called
as a function, a class method, or an object method.  Whatever
syntax tickles your fancy is acceptable.

=head2 ARGUMENTS:

Takes two scalar arguments, though the second is optional.  The
first is the number of bits of randomness to produce.  The second
is the strength of randomness.  See L<Crypt::Random> for more
details.  A 0, which is the default, is not guaranteed to produce
high quality randomness if used frequently.  A strength of 1
is guaranteed to produce high quality randomness, though it may
be slower than a strength 0 call, especially if invoked often.

The arguments can be passed via a hash ref with keys of
BITS and STRENGTH.

=head2 RETURNS:

A scalar containing the random string.  These are packed bits,
so use unpack to turn them into something readable, if that
is desired.

=head2 EXAMPLE

  $key = Enigo::Common::Crypt::generateKey(448,1);
  print "The key is: ",unpack('H112',$key),"\n";

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub generateKey
  {
    shift(@_) if ($_[0] !~ /^\d+$/ and ref($_[0]) ne 'HASH');
    my $param = {BITS => 448,
         STRENGTH => 1};

    if (ref($_[0]))
      {
    $param->{BITS} =
      $_[0]->{BITS} ? $_[0]->{BITS} : $param->{BITS};
    $param->{STRENGTH} =
      exists($_[0]->{STRENGTH}) ? 
        $_[0]->{STRENGTH} : $param->{STRENGTH};
      }
    else
      {
    $param->{BITS} = $_[0] ? $_[0] : $param->{BITS};
    $param->{STRENGTH} =
      defined $_[1] ? $_[1] : $param->{STRENGTH};
      }

    my $hexkey = '';
    my $pack_template_count = 0;

    while ($param->{BITS} > 0)
      {
    my $little_bits =
      ($param->{BITS} - 8 > 7) ? 8 : $param->{BITS};
    $param->{BITS} -= 8;

    if ($Enigo::Common::Crypt::has_Crypt_Random) {
      $hexkey .= unpack('H2',
                pack('i',
                 Crypt::Random::makerandom
                 (Size => $little_bits,
                  Strength => $param->{STRENGTH})));
    } else {
      $hexkey .= _makerandom($little_bits);
    }
    $pack_template_count += 2;
      }
    
    return pack("H$pack_template_count",$hexkey);
  }


#Crypt::Random isn't here, so we make do.
sub _makerandom {
  my $size = shift;

  my $bits = $size;
  my $total;

  while ($bits > 0) {
    my $value;
    if (-r '/dev/random') {
      open(RANDOM,"</dev/random");
      $value = getc(RANDOM);
      close RANDOM;
      $value += 128;
    } else {
      $value = int(rand() * 256);
    }

    my $mask = ($bits >7) ? 8 : $bits;
    $bits -= 8;
    $value &= (2**$mask - 1);
    $total .= pack('C',$value);
  }

  my $bytes = 2 * length($total);
  return unpack("H$bytes",$total);
}


######################################################################
##### Method: randomKey
######################################################################

=pod

=head2 METHOD_NAME: randomKey

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 30 Jun 2000>

=head2 PURPOSE:

Generate and return a random cryptographic key based on the
cipher the key is going to be used for.  This method
will look at the name of the cipher in order to determine
the largest key useable by that cipher, and then will
generate one to fit that size requirement.

=head2 ARGUMENTS:

Takes a single scalar argument, the name of the cipher
that the key is being generated for, if being called as a
function.  If being called as a method, C<randomKey()>
does not need any arguments to be passed to it.  It will
default to the cipher being used by the
Enigo::Common::Crypt object.

The argument can be passed via a hash ref with a key of
CIPHER.

=head2 RETURNS:

A scalar containing the key.

=head2 EXAMPLE

  $key = Enigo::Common::Crypt::randomKey('Blowfish');
  print "The key is: ",unpack('H112',$key),"\n";

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub randomKey
  {
    my $cipher;
    
    if (ref($_[0]) =~ /Enigo::Common::Crypt/ and defined ($_[1]))
      {
    shift(@_);
      }
    
    if (ref($_[0]))
      {
    $cipher = $_[0]->{CIPHER};
      }
    else
      {
    $cipher = shift;
      }

    return generateKey({STRENGTH => 1,
            BITS => &{sub
            {
              #Return the key length for various
              #encryption ciphers.  If the
              #cipher is not recognized, a
              #64 bit key is returned.
              $cipher =~ /blowfish/i && do
                {return 448};
              $cipher =~ /idea/i && do
                {return 128};
              $cipher =~ /tripledes/i && do
                {return 384};
              $cipher =~ /des/i && do
                {return 64};
              return 64;
            }}});
  }



######################################################################
##### Method: encrypt
######################################################################

=pod

=head2 METHOD_NAME: encrypt

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 30 Jun 2000>

=head2 PURPOSE:

Encrypts a scalar.

=head2 ARGUMENTS:

A scalar containing the plaintext to be encrypted.

=head2 RETURNS:

A scalar containing the encrypted data.

=head2 THROWS

  Enigo::Common::Exception::Crypt::EncryptFailed
    Thrown if the encryption fails for any reason.

=head2 EXAMPLE

  my $encrypted_text = $cipher->encrypt($plaintext);

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub encrypt
  {
    my $self = shift;
    my $plaintext = shift;

    my $ciphertext;
    eval
      {
    $ciphertext = $self->{CRYPT_OBJECT}->encrypt($plaintext);
      };
    throw Enigo::Common::Exception::Crypt::EncryptFailed
      ({CIPHER => ref($self->{CIPHER})}) if $@;

    return $ciphertext;
  }


######################################################################
##### Method: decrypt
######################################################################

=pod

=head2 METHOD_NAME: decrypt

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 30 Jun 2000>

=head2 PURPOSE:

Decrypts ciphertext and returns plaintext.

=head2 ARGUMENTS:

Takes a single scalar argument, the ciphertext to decrypt.

=head2 RETURNS:

A single scalar argument, the decrypted plaintext.

=head2 THROWS:

  Enigo::Common::Exception::Crypt::DecryptFailed
    Thrown if the decryption fails for any reason.

=head2 EXAMPLE

  my $plaintext = $cipher->decrypt($ciphertext);

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub decrypt
  {
    my $self = shift;
    my $ciphertext = shift;

    my $plaintext;
    eval
      {
    $plaintext = $self->{CRYPT_OBJECT}->decrypt($ciphertext);
      };
    throw Enigo::Common::Exception::Crypt::DecryptFailed
      ({CIPHER => ref($self->{CIPHER})}) if $@;
    
    return $plaintext;
  }



sub key
  {
    my $self = shift;

    return $self->{KEY};
  }

1;
