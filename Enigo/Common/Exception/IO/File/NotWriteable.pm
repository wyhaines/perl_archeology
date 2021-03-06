package Enigo::Common::Exception::IO::File::NotWriteable;

use strict;

require Error;
require Enigo::Common::Exception::IO::File;

@Enigo::Common::Exception::IO::File::NotWriteable::ISA =
  qw(Error Enigo::Common::Exception::IO::File);
$Enigo::Common::Exception::IO::File::NotWriteable::VERSION = '2000_05_21_21_09';

##### Introductory Comment

=pod

=head1 Enigo::Common::Exception::IO::File::NotWriteable

B<10 May 2000>

This is an exception class for use with Graham Barr's Error package.
It should be thrown when a filesystem access was attempted, but the target
of that access, while existing, was not writeable.

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
written to.

=item exception value

This is an exit value to return to the system.  Defaults to 0.

=back

Returns a HASH blessed into Enigo::Common::Exception::IO::File::NotWriteable
as a subclass of L<Error>.  The constructor takes one, or optionally, two
arguments.

C<
throw Enigo::Common::Exception::FileNotWriteable
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

    $text = "Error: FileNotWriteable: $text could not be written to";
    push(@args,'-value',0 + $value) if defined($value);
    return bless(Error->new(-text => $text, @args),$self);
  }
