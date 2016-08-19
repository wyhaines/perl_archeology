package Enigo::Common::Exception::Eval;

use strict;

require Error;
require Enigo::Common::Exception;
use Term::ANSIColor;

@Enigo::Common::Exception::Eval::ISA =
  qw(Error Enigo::Common::Exception);
$Enigo::Common::Exception::Eval::VERSION = '2000_05_18_13_22';

##### Introductory Comment

=pod

=head1 Enigo::Common::Exception::Eval

B<18 May 2000>

This is an exception class for use with Graham Barr's Error package.
This exception is appropriate for any errors that occur within the context
of an eval() statement.

Z<>
Z<>

=cut
#####


##### Constructor: new

=pod

=head2 Constructor: new

=head2 Arguments

=over 4

=item eval'd code

If the eval'd code that caused the error is passed into the exception,
the exception's error message will output the offending line along with
a few lines of context surrounding the exception.

=back

Returns a HASH blessed into Enigo::Common::Exception::Eval
as a subclass of L<Error>.  The constructor takes one argument.

C<
eval($a);
throw Enigo::Common::Exception::Eval($a) if ($@);
>

Z<>

Z<>

=cut
#####

sub new
  {
    my ($self) = shift;
    my ($code) = shift;
    my ($value) = shift;

    my @args;

    local $Error::Depth = $Error::Depth + 1;

    my $error_text = $@;
    $@ =~ / at (.*?) line (\d+)/;
    my $file = $1;
    my $line = $2;
    my $zero_adjusted_line = $line - 1;
    my $first_context_line =
      $zero_adjusted_line > 4 ? $zero_adjusted_line - 5 : 0;
    my $first_context_count =
      $first_context_line ? 5 : $zero_adjusted_line;
    @args = (-file => $file,
             -line => $code);
    my $text;

    if ($code)
      {
    my $regexp = '^';
        $regexp .= '(?:[^\n]*\n){' . $first_context_line . '}' 
      if ($first_context_line > 0);
    $regexp .= '?(' . '[^\n]*\n' x $first_context_count;
    $regexp .= ')([^\n]*(?:\n|$))(' . '[^\n]*(?:\n|$)' x 2;
    $regexp .= ')';
    $code =~ /^$regexp/m;
    my $first_context = $1;
    my $line = $2;
    my $last_context = $3;
    $text = join('',
             "Error: Eval: $@\n",
             $1,
             color('bold'),
             $2,
             color('reset'),
             $3,
             "\n");
      }
    else
      {
    $text = "Error: Eval: $@";
      }
    push(@args,'-value',0 + $value) if defined($value);
    return bless(Error->new(-text => $text, @args),$self);
  }
