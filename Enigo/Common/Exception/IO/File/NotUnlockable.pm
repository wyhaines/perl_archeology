package Enigo::Common::Exception::IO::File::NotUnlockable;
#Would there _ever_ be an error resulting from a failed flock(LOCK_UN)?
use strict;

require Error;
require Enigo::Common::Exception::IO::File;

@Enigo::Common::Exception::IO::File::NotUnlockable::ISA =
  qw(Error Enigo::Common::Exception::IO::File);
$Enigo::Common::Exception::IO::File::NotUnlockable::VERSION = '2000_05_10_13_14';

##### Introductory Comment

=pod

=head1 Enigo::Common::Exception::IO::File::NotUnlockable

B<11 May 2000>

This is an exception class for use with Graham Barr's Error package.
This exception should be thrown when an attempt is made to unlock a file,
but that attempt failed (i.e. when an error occurs as a result of an
attempt to use flock to issue a LOCK_UN).

Z<>
Z<>

=cut
#####


##### Constructor: new

=pod

=head2 Constructor: new

=head2 Arguments

=over 4

=item filesystem path

This is a scalar containing path to the filesystem item that could not be
unlocked.

=item exception value

This is an exit value to return to the system.  Defaults to 0.

=back

Returns a HASH blessed into
Enigo::Common::Exception::IO::File::NotUnlockable
as a subclass of L<Error>.  The constructor takes one, or optionally, two
arguments.

C<
throw Enigo::Common::Exception::IO::File::NotUnlockable
  ('/var/log/mylog.log');
>

Z<>
Z<>

=cut
#####

sub new
  {
    my ($self) = shift;
    my ($text) = shift;
    my ($value) = shift;

    my @args;

    local $Error::Depth = $Error::Depth + 1;

    @args = (-file => $1,
             -line => $2)
      if($text =~ s/ at (\S+) line (\d+)(\.\n)?$//s);

    $text = "Error: FileNotUnlockable: $text could not be locked";
    push(@args,'-value',0 + $value) if defined($value);
    return bless(Error->new(-text => $text, @args),$self);
  }
