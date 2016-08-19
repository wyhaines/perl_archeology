#!/usr/bin/perl -wc
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: $RCSfile: TempFile.pm,v $

Z<>

I<REVISION: $Revision: 1.1.1.1 $>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: $Date: 2001/12/17 02:28:37 $>

=head1 PURPOSE:

Provides a subclass of IO::File that automatically removes the
file created when the object goes out of scope.

=head1 EXAMPLE:

  my $tmpfile = Enigo::Common::IO::TempFile->new("> /tmp/tmpfile.$$");

Z<>

=head1 TODO:

=head1 DESCRIPTION:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

package Enigo::Common::IO::TempFile;

use strict;
use vars qw($VERSION @ISA);

use Symbol;
use Cwd;
require IO::File;
@ISA = qw(IO::File);

($VERSION) =
  '$Revision: 1.1.1.1 $' =~ /\$Revision:\s+([^\s]+)/;#';


######################################################################
##### Constructor: new
######################################################################

=pod

=head2 CONSTRUCTOR_NAME: new

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 18 Oct 2001>

=over 4

=item PURPOSE:

Returns a new Enigo::Common::IO::TempFile object/filehandle.

=item ARGUMENTS:

Same as IO::File.

=item THROWS:

nothing

=item RETURNS:

Returns a new Enigo::Common::IO::TempFile object/filehandle.

=item EXAMPLE:

  my $tmpfile = Enigo::Common::IO::TempFile->new("> /tmp/tmpfile.$$");

Z<>

=item TODO:

=back

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub new {
  my ($proto) = shift;
  my ($class) = ref($proto) || $proto;
  my $self = $class->SUPER::new();
  bless ($self, $class);
  if (@_) {
    $self->open(@_);
  }

  return $self;
}


######################################################################
##### Method: open
######################################################################

=pod

=head2 METHOD_NAME: open

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 18 Oct 2001>

=over 4

=item PURPOSE:

Subclasses IO::File::open in order to store the path of the opened
file so that it can be unlinked later.

=item ARGUMENTS:

Same as IO::File::open

=item THROWS:

nothing

=item RETURNS:

Same as IO::File::open

=item EXAMPLE:

  $tmpfile->open("> /tmp/tmpfile.$$");

Z<>

=item TODO:

=back

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################


sub open {
  my $self = shift;
  my ($filename) = @_;

  #####
  #Strip read/write/append markers from the front of the filename
  #and then make sure that the filename is an absolute path
  #before storing it.
  #####
  $filename =~ s/^[\<\>\+]*\s*(.*)$/$1/;
  return undef unless $self->SUPER::open(@_);
  my $dir = $filename; $dir =~ s{([^/]*)$}{};
  $filename = Cwd::abs_path($dir) . "/$1";
  *{$self} = \$filename;

  return $self;
}


######################################################################
##### Method: get_the_name
######################################################################

=pod

=head2 METHOD_NAME: get_the_name

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 18 Oct 2001>

=over 4

=item PURPOSE:

Returns the filename associated with the object.

=item ARGUMENTS:

none

=item THROWS:

nothing

=item RETURNS:

A scalar containing a filename.

=item EXAMPLE:

  my $filename = $tmpfile->get_the_filename;

Z<>

=item TODO:

=back

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub get_the_name {
  my $self = shift;

  return ${*{$self}{SCALAR}};
}


sub unlink {
  my $self = shift;

  eval {
    unlink $self->get_the_name();
  };

  *{$self} = \undef;
}


sub _unlink {
  my $self = shift;
  $self->unlink(@_);
}

######################################################################
##### Method: DESTORY
######################################################################

=pod

=head2 METHOD_NAME: DESTROY

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 18 Oct 2001>

=over 4

=item PURPOSE:

Gets called when the object is being garbage collected.  This will
unlink the file associated with the object.

=item ARGUMENTS:

n/a

=item THROWS:

n/a

=item RETURNS:

n/a

=item EXAMPLE:

n/a

=item TODO:

=back

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub DESTROY {
  my $self = shift;

  #####
  #Wrapped in an eval in case the file is already gone.  We don't
  #want to be pitching errors out of DESTROY();
  #####
  eval {
    unlink $self->get_the_name();
  };
}

1;
