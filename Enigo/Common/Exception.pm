#!/usr/bin/perl -wc
# 
######################################################################
##### Header
######################################################################
=pod

=head1 FILE_NAME: Exception.pm

=head1 Enigo::Common::Exception

I<REVISION: $Revision: 1.1.1.1 $>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: $Date: 2001/12/17 02:28:37 $>

=head1 PURPOSE:

This is an exception class for use with C<Error.pm>.
Enigo::Common::Exception itself should not be thrown.  It is used
as a superclass for other Enigo:Common::Exception::* classes,
implementing some common methods.  It also implements an import()
method which is intended to be used to pull in needed sets of
exceptions for a given program or module.

=head1 TODO:

There a copious types of exceptions that support needs to be created for.

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

package Enigo::Common::Exception;

use strict;

use Text::Wrap ();
require Error;
use overload
  '""' => \&stringify;


@Enigo::Common::Exception::ISA = qw(Error Exporter);
$Enigo::Common::Exception::VERSION = '1.9.46.4';



######################################################################
##### Method: import
######################################################################

=pod

=head2 METHOD_NAME: import

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 2000 May 15>

=head2 PURPOSE:

This module provides an C<import()> interface to allow for inclusion of
whole sets of related exception classes based on the tags provided in the
C<use> statement.

It also serves as the superclass for all of the exception classes.  As such,
a:

C<catch Enigo::Common::Exception with {BLOCK};> statement will catch any
thrown exception in the Enigo::Common::Exception::* hierarchy.

=head2 ARGUMENTS:

The method accepts a list of import flags, each of which directs import()
to I<require> a specific set of exceptions.

The valid flags, and the exceptions they cause to be I<require>d are:

=over 4

=item :IO

I<:IO> causes all exceptions defined under I<:file>, I<:db>, and I<:net>,
each of which are defined below, to be made available.

=item :file

This makes file access related exceptions available.

=over 4

=item These are:

I<Enigo::Common::Exception::IO::File>

I<Enigo::Common::Exception::IO::File::NotFound>

I<Enigo::Common::Exception::IO::File::NotReadable>

I<Enigo::Common::Exception::IO::File::NotCloseable>

I<Enigo::Common::Exception::IO::File::NotLockable>

I<Enigo::Common::Exception::IO::File::NotUnlockable>

=back

=item :DB

Database related exceptions.

=over 4

=item These are:

I<Enigo::Common::Exception::IO::DB>

I<Enigo::Common::Exception::IO::DB::CouldNotConnect>

=back

=item :net

Exceptions for network connection related events.

=over 4

I<Enigo::Common::Exception::IO::Net::CouldNotConnect>

=back

=item :general

Makes available a general purpose exception.

=over 4

I<Enigo::Common::Exception::General>

=back   

=item :eval

An exception for eval() errors.

=over 4

I<Enigo::Common::Exception::Eval>

=back

=back


=head2 RETURNS:

undef

=head2 EXAMPLE:

  use Enigo::Common::Exception qw(:IO :Eval);

  try
    {
      BLOCK
    }
  catch Enigo::Common::Exception with
    {
      BLOCK
    };

  @ISA = qw(Enigo::Common::Exception);

=head2 TODO:

There are a lot of exceptions that need to be supported within
C<import()>.

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub import {
  my $package = shift;
  my $import_arg = shift || '';
  {
    $import_arg eq ':IO' && do {
      push(@_,qw(:file :DB :net));
      require Enigo::Common::Exception::IO;
      import($package,@_);
    };
    $import_arg eq ':eval' && do {
      require Enigo::Common::Exception::Eval;
      import($package,@_);
    };
    $import_arg eq ':file' && do {
      require Enigo::Common::Exception::IO::File;
      require Enigo::Common::Exception::IO::File::NotFound;
      require Enigo::Common::Exception::IO::File::NotReadable;
      require Enigo::Common::Exception::IO::File::NotCloseable;
      require Enigo::Common::Exception::IO::File::NotLockable;
      require Enigo::Common::Exception::IO::File::NotUnlockable;
      import($package,@_) if (@_);
    };
    $import_arg eq ':DB' && do {
      require Enigo::Common::Exception::IO::DB;
      require Enigo::Common::Exception::IO::DB::CouldNotConnect;
      require Enigo::Common::Exception::IO::DB::PrepareFailed;
      require Enigo::Common::Exception::IO::DB::ExecuteFailed;
      import($package,@_) if (@_);
    };
    $import_arg eq ':net' && do {
      require Enigo::Common::Exception::IO::Net::CouldNotConnect;
      import($package,@_) if (@_);
    };
    $import_arg eq ':general' && do {
      require Enigo::Common::Exception::General;
      import($package,@_) if (@_);
    };
    $import_arg eq ':Config' && do {
      require Enigo::Common::Exception::Config;
      require Enigo::Common::Exception::Config::UndefinedConfiguration;
      require Enigo::Common::Exception::Config::FailedInitialization;
      import($package,@_) if (@_);
    };
  }
  
  return undef;
}


######################################################################
##### Constructor: new
######################################################################

=pod

=head2 CONSTRUCTOR_NAME: new

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 15 Jun 2000>

=head2 PURPOSE:

Returns a hash ref blessed into an exception class.  This constructor
implements all of the code common to all Enigo::Common::Exception
subclasses.

=head2 ARGUMENTS:

Expects either two scalar arguments, the text of the exception and the
value of the exception, or a hashref with TEXT and ERROR parameters
containing those items.

=head2 RETURNS:

A hashref blessed into Enigo::Common::Exception.

=head2 EXAMPLE

  @ISA = qw(Enigo::Common::Exception);
  sub new
    {
      my $self = shift;
      my $file = shift;
      my $value = shift;

      my $text = "Error: FileNotFound: The file, '$file', could not be found.";
      local $Error::Depth = $Error::Depth + 1;
      return bless $self->SUPER->new({TEXT => $text,
                                      VALUE => $value}),
                   $self;
    }

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub new {
  my $self = shift;

  my $param = {TEXT => '',
           VALUE => 1};

  if (ref($_[0]) eq 'HASH') {
    $param->{TEXT} = $_[0]->{TEXT};
    $param->{VALUE} = $_[0]->{VALUE};
  } else {
    $param->{TEXT} = $_[0];
    $param->{VALUE} = ($_[1] || $param->{VALUE});
  }

  #Increase the depth counter so that within the Error::new() method,
  #the correct call frame can be referenced to determine where the
  #exception was thrown.
  ####
  local $Error::Depth = $Error::Depth + 1;
  my $exception = Error::new($self);
  $exception->{-stacktrace} = undef
    unless (exists $exception->{-stacktrace});

  my $stacktrace_message = undef;
  $stacktrace_message = <<ETXT if ($exception->{-stacktrace});
Stack Trace
-----------
$exception->{-stacktrace}
ETXT
  #We'd also like to know the name of the subroutine, if any, that
  #the code execution path was in when the exception was thrown.
  #To get this info, we need to reference a call frame one level
  #higher than the frame that Error::new() referenced.  However,
  #since the depth was incremented before Error::new() was called,
  #and since the 'caller' function invoked therein was invoked
  #at a call frame one level below the current frame, using the
  #same depth that was used in Error::new(), here, will return the
  #information for the next level up, which gives us the subroutine
  #name that we want.
  ####
  my $exception_thrown_in_subroutine = (caller($Error::Depth + 1))[3];
  my $subroutine_line = $exception_thrown_in_subroutine ?
    ", within subroutine $exception_thrown_in_subroutine." :
      '.';
  $param->{TEXT} =~ s|<ERROR_LOCATION/>|$exception->{-package} at $exception->{-file} line $exception->{-line}$subroutine_line|gi;
  $Text::Wrap::columns = 70;
  local $^W = 0; #Text::Wrap isn't warnings safe
  $param->{TEXT} = Text::Wrap::wrap(undef,undef,$param->{TEXT});
  $param->{TEXT} .= $stacktrace_message;
  $^W = 1;
  $param->{VALUE} += 0;
  $exception->{-text} = $param->{TEXT};
  $exception->{-value} = $param->{VALUE};
  
  return $exception;
}



######################################################################
##### Method: attach
######################################################################

=pod

=head2 METHOD_NAME: attach

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 11 Jun 2000>

=head2 PURPOSE:

Attach another exception to the current exception object.  This allows
a backtrace of exceptions -- exception A triggered exception B ...
triggered exception X -- to be recorded and presented from a single
subsequent call to fatal(), nonfatal(), or stringify().

=head2 ARGUMENTS:

Takes a list of exception object to attach the the current object.

=head2 RETURNS:

undef

=head2 EXAMPLE

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub attach {
  my $self = shift;
  
  $self->{ATTACHMENTS} = [@_];
  
  return undef;
}



######################################################################
##### Method: fatal
######################################################################

=pod

=head2 METHOD_NAME: fatal 

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 15 May 2000>

=head2 PURPOSE:

Prints itself to STDERR, then exists with the exit value set to the
B<value> of the exception.  I<fatal()> checks to see if it is running in a mod_perl
context, and if it is, executes I<Apache::exit()> instead of I<exit()>.

=head2 ARGUMENTS:

None.

=head2 RETURNS:

undef

=head2 EXAMPLE:

  try
    {
      BLOCK
    }
  catch Enigo::Common::Exception with
    {
      my $exception = shift;
      $exception->fatal();
    }

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub fatal {
  my ($self) = shift;
  
  $self->nonfatal();
  if ($ENV{MOD_PERL}) {
    Apache::exit($self->value);
  } else {
    local $^W = 0;
    exit($self->value);
  }
  
  return undef;
}



######################################################################
##### Method: nonfatal
######################################################################

=pod

=head2 METHOD_NAME: nonfatal 

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 15 May 2000>

=head2 PURPOSE:

The exception prints itself to STDERR, and then returns.

=head2 ARGUMENTS:

None.

=head2 RETURNS:

The text of the exception.

=head2 EXAMPLE:

  try
    {
      BLOCK
    }
  catch Enigo::Common::Exception with
    {
      my $exception = shift;
      my $error_text = $exception->nonfatal();
    }

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub nonfatal {
  my ($self) = shift;
  my $text = $self->stringify();
  print STDERR $text,"\n";
  
  return $text;
}



######################################################################
##### Method: stringify
######################################################################

=pod

=head2 METHOD_NAME: stringify

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 15 May 2000>

=head2 PURPOSE:

Return a textual description of the exception as a scalar.

=head2 ARGUMENTS:

None.

=head2 RETURNS:

A scalar containing the textual description of the exception.

=head2 EXAMPLE:

  my $error_text = $exception->stringify();  

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub stringify {
  my ($self) = shift;
  
  my $text;
  foreach my $exception (@{$self->{ATTACHMENTS}}) {
    next unless $exception->can('stringify');
    $text .= $exception->stringify() . "\n";
  }
  
  $text .= $self->SUPER::stringify;
  $text .= sprintf(" at %s line %d.\n$!", $self->file, $self->line)
    unless($text =~ /\n$/s);
  
  return $text;
}

1;
