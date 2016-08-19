#!/usr/bin/perl -wc
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: $RCSfile: TempDir.pm,v $

Z<>

I<REVISION: $Revision: 1.1.1.1 $>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: $Date: 2001/12/17 02:28:37 $>

=head1 PURPOSE:

Enigo::Common::IO::TempDir provides a subclass of IO::Dir that
maintains knowledge of all of the TempDir and TempFile entities
underneath of it, and automatically cleans them up when the
object goes out of scope.


=head1 EXAMPLE:

  my $tmpdir = Enigo::Common::IO::TempDir->new("/tmp/tmpdir");

This will create a $tmpdir object that owns /tmp/tmpdir.

  my $underling = $tmpdir->open("/tmp/tmpdir/royal_court/underling");
  $tmpdir->open("royal_court/flunkie");

Z<>

=head1 TODO:

  Complete documentation.
  Make find_node() more efficient.

=head1 DESCRIPTION:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

package Enigo::Common::IO::TempDir;

use strict;
use vars qw($VERSION @ISA);

use Symbol;
use Cwd;
use Fcntl qw(:DEFAULT);
require IO::Dir;
@ISA = qw(IO::Dir);

($VERSION) =
  '$Revision: 1.1.1.1 $' =~ /\$Revision:\s+([^\s]+)/;#';


######################################################################
##### Constructor: new
######################################################################

=pod

=head2 CONSTRUCTOR_NAME: new

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 24 Oct 2001>

=over 4

=item PURPOSE:

Returns a new Enigo::Common::IO::TempDir object.

=item ARGUMENTS:

Same as IO::File.

=item THROWS:

nothing

=item RETURNS:

Returns a new Enigo::Common::IO::TempFile object.

=item EXAMPLE:

  my $tmpdir = Enigo::Common::IO::TempDir->new("/tmp/tmpdir");

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
  if (@_) {
    return $proto->open(@_);
  }

  my ($class) = ref($proto) || $proto;
  my $self = $class->SUPER::new();
  bless ($self, $class);
  *{$self} = [];
  return $self;
}


######################################################################
##### Method: open
######################################################################

=pod

=head2 METHOD_NAME: open

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 24 Oct 2001>

=over 4

=item PURPOSE:

Subclasses IO::Dir::open in order to store the path of the opened
file so that it can be unlinked later.

=item ARGUMENTS:

Same as IO::Dir::open

=item THROWS:

nothing

=item RETURNS:

Same as IO::Dir::open

=item EXAMPLE:

  $tmpdir->open("/tmp/tmpdir");

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
  my ($dirname,$perms,$remaining) = @_;
  $perms = $perms ? $perms : 0775;

  #// If $remaining is null then this is the first call into here.
  #// If we have recursed into here then it will have something in it.
  #// That thing will either be a scalar value or a scalar ref.
  #// Because we want to distinguish between a $remaining that is
  #// empty because this is the first call to open() and one that is
  #// empty because we've traversed the whole tree, if there is a
  #// ref in $remaining, that will be treated as a signal that the
  #// whole tree has been traversed.
  unless ($remaining) {
    $remaining = $dirname;
    $remaining =~ s{^/}{};
  }

  if (ref $self) {
    #// Check the path that we are opening.  If it is specified as a
    #// relative path, we need to make it absolute, first.
    unless ($dirname =~ m{^/}) {
      $dirname = join('',
              $self->get_the_name,
              '/',
              $dirname);
    }

    #// Get the path of this object and make sure that it is above
    #// the path of the dir we are being asked to create.
    {
      my $local_path = $self->get_the_name;
      return undef unless ($dirname =~ m{$local_path});
    }

    #// Determine the next path to check by subtracting the remaining
    #// dir portion from the whole dirname.  Then reduce $remaining.
    my $next_path;
    my $next_remaining;
    {
      $next_path = $dirname;
      $next_remaining = $remaining;
      $next_remaining = '' if ref $next_remaining;
      $next_path =~ s{$next_remaining}{} if $next_remaining ne '';
      $next_remaining =~ s{^[^/]*/?}{};
      unless ($next_remaining ne '') {
    $next_remaining = \'null'; #';
      }
    }

    #//Check to see if the path exists.
    if (-e $next_path) {
      #//  See if we can find an object for it.
      my $found_node = $self->find_node($next_path);

      #// If this object IS the one that has $next_path, and $remaining
      #//   is a ref, just return ourselves.
      if ($self->get_the_name eq $next_path and
      ref $remaining) {
    return $self;

    #// If we can, and if there is still some path left to traverse
    #//   call open() again with the remainder.
      } elsif ($found_node and !ref $remaining) {
    return $found_node->open($dirname,$perms,$next_remaining);

    #//  If there is no path left to traverse, just return the current
    #//    object.
      } elsif ($found_node and ref $remaining) {
    return $found_node;

    #//  Else we can't find an object for it, and the path already
    #//    exists, so we can't take ownership.  If nothing more is
    #//    remaining to traverse, return undef, else traverse to the
    #//    next level.
      } elsif (ref $remaining) {
    return undef;
      } else {
    return $self->open($dirname,$perms,$next_remaining);
      }
      #//
      #//  If it does not, create an object for it and pass the remainder
      #//    of the path on to that object.
    } else {
      mkdir($next_path,$perms);
      $! = '';
      my ($class) = ref($self) || $self;
      my $new_node = $class->SUPER::new();
      *{$new_node} = [];
      bless ($new_node, $class);
      $new_node->set_the_name($next_path);
      $self->_add($new_node);
      return $new_node->open($dirname,$perms,$next_remaining);
    }
  } else {
    my $next_path;
    my $next_remaining;
    {
      $next_path = $dirname;
      $next_remaining = $remaining;
      $next_remaining = '' if ref $next_remaining;
      $next_path =~ s{$next_remaining}{} if $next_remaining ne '';
      $next_remaining =~ s{^[^/]*/?}{};
      unless ($next_remaining ne '') {
    $next_remaining = \'null'; #';
      }
    }

    #// Check to see if the path exists.
    if (-e $next_path) {
      #// It exists, and since we aren't within the context of an object, yet,
      #// we have to assume that it exists outside of a TempDir context, so
      #// we really shouldn't take control of the dir and make it a temporary
      #// directory, right?  It would not be good, right?  Yeah, right.
      #// But wait!  Don't give up just yet.  What if we haven't traversed
      #// the whole dirname, yet?  If there is anything left in the dirname,
      #// we need to descend down into it.
      if (ref $remaining) {
    #// Drag, we're at the end of our rope.  Return an undef.
    return undef;
      } else {
    #// Bonus!  There's still more path to check.  Let's do it!
    $self->open($dirname,$perms,$next_remaining);
      }
    } else {
      #// Well, it doesn't exist!  Awesome.  Okeydokey.  Time to create an
      #// object.
      my $new_self = $self->SUPER::new();
      bless ($new_self, $self);
      *{$new_self} = [];
      mkdir $next_path,$perms;
      $! = '';
      $new_self->set_the_name($next_path);
      return $new_self->open($dirname,$perms,$next_remaining);
    }
  }
}


sub _add {
  my $self = shift;
  my $new_node = shift;
  push @{*{$self}{ARRAY}},$new_node;

  return *{$self}{ARRAY};
}

*makeDir = \&open;
*openDir = \&open;

sub openFile {
  my $self = shift;
  my $wholepath = shift;
  my $mode;
  my $perms;
  if ($wholepath !~ m{^[+<>\-|]+}) {
    $mode = shift || O_CREAT | O_WRONLY;
    $perms = shift || 0775;
  }

  #####
  #Generate a path minus the filename
  #####
  $wholepath =~ m{^(?:[\+\-\<\>\|]*)(.*?)/[^/]+$ }x;
  my $partial_path = $1;

  my $open_node;
  #####
  #Figure out which node owns that path.
  #####
  if ($partial_path eq $self->get_the_name) {
    $open_node = $self;
  } else {
    $self->openDir($partial_path,$perms);
    $open_node = $self->find_node($partial_path);
    $open_node = $open_node ? $open_node : $self;
  }
  #####
  #Create the temporary file.
  #####
  my $new_file = defined $mode ?
    Enigo::Common::IO::TempFile->new($wholepath,$mode,$perms) :
    Enigo::Common::IO::TempFile->new($wholepath);
  #####
  #Give that file to the node that owns the dir it lives in.
  #####
  *{$open_node} = [] unless defined *{$open_node}{ARRAY};
  push @{*{$open_node}{ARRAY}},$new_file;

  return $new_file
}


sub writeFile {
  my $self = shift;
  my $path = shift;
  my $contents = shift;
  my $mode;
  my $perms;
  if ($path !~ m{^[+<>\-|]+}) {
    $mode = shift || O_CREAT | O_WRONLY;
    $perms = shift || 0775;
  }

  my $fh = $self->openFile($path,$mode,$perms);
  $fh->print($contents);
  $fh->seek(0,0);

  return $fh;
}


sub unlink {
  my $self = shift;
  my $path = shift;

  my $node = $self->find_node($path);

  $node->_unlink($path);
}


sub _unlink {
  my $self = shift;

  $self->NUKE();
  $! = '';
}


sub find_node {
  my $self = shift;
  my $path = shift;

  if (defined *{$self}{ARRAY}) {
    foreach my $node (@{*{$self}{ARRAY}}) {
      my $name = $node->get_the_name;

      #####
      #If we find it, return.
      #####
      if ($name eq $path) {
    return $node;
    #####
    #Otherwise check to see if the node is a dir.  If it is,
    #we want to have that node see if it contains the target.
    #If it does, we'll return that.
    #####
      } elsif (ref($node) =~ /TempDir/) {
    my $deeper_node = $node->find_node($path);
    return $deeper_node if $deeper_node;
      }
    }
  }
  #####
  #Bummer.  Nothing had the target.
  #####
  return undef;
}



######################################################################
##### Method: get_the_name
######################################################################

=pod

=head2 METHOD_NAME: get_the_name

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 24 Oct 2001>

=over 4

=item PURPOSE:

Returns the dirname associated with the object.

=item ARGUMENTS:

none

=item THROWS:

nothing

=item RETURNS:

A scalar containing a filename.

=item EXAMPLE:

  my $dirname = $tmpdir->get_the_name;

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


######################################################################
##### Method: set_the_name
######################################################################

=pod

=head2 METHOD_NAME: set_the_name

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 31 Oct 2001>

=over 4

=item PURPOSE:

Sets the dirname associated with the object.

=item ARGUMENTS:

none

=item THROWS:

nothing

=item RETURNS:

nothing

=item EXAMPLE:

  $tmpdir->set_the_name($dirname);

Z<>

=item TODO:

=back

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub set_the_name {
  my $self = shift;
  my $dirname = shift;

  *{$self} = \$dirname;
}


######################################################################
##### Method: DESTORY
######################################################################

=pod

=head2 METHOD_NAME: DESTROY

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 24 Oct 2001>

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
  #When we DESTROY(), we want to traverse our tree down to the ends
  #and cleanup everything that we find along the way in a recursive,
  #depth first way.  This way, if we create a top level dir with this
  #class, then create other files and dirs under it through the first
  #object, all we have to do is let that single object go out of scope
  #and the entire tree gets cleaned up, both files and dirs.
  #####

  no strict qw(vars refs);
  local $recursive_destroy = sub {
    my $node = shift;

    eval {
      if (*{$node}{ARRAY}) {
    foreach my $subnode (@{*{$node}{ARRAY}}) {
      &$recursive_destroy($subnode) if $subnode->get_the_name;
    }
      }
    };
    *{$node} = \undef;
    *{$node} = [];
    undef $node;
  };

  eval {
    if (*{$self}{ARRAY}) {
      foreach my $node (@{*{$self}{ARRAY}}) {
    &$recursive_destroy($node) if $node->get_the_name;
      }
    }
  };

  system("rm -rf " . $self->get_the_name) if ($self->get_the_name);
  $! = '';
  use strict qw(vars refs);
  return undef;
}


######################################################################
##### Method: NUKE
######################################################################

=pod

=head2 METHOD_NAME: NUKE

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 31 Oct 2001>

=over 4

=item PURPOSE:

This method is a near duplicate of DESTROY.  The difference is that
NUKE() is invoked when unlink() is explicitly called on an object.
It will traverse its tree and unlink everything below it, then
will clean itself up.  The cleanup involves removing the directory
owned by the object, clearing its array of owned directories and
files and clearing its name scalar.  Thus, the object will still
exist, but it will be empty.

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

sub NUKE {
  my $self = shift;

  #####
  #When we NUKE(), we want to traverse our tree down to the ends
  #and cleanup everything that we find along the way in a recursive,
  #depth first way.  This way, if we create a top level dir with this
  #class, then create other files and dirs under it through the first
  #object, all we have to do is let that single object go out of scope
  #and the entire tree gets cleaned up, both files and dirs.
  #####

  foreach my $subnode (@{*{$self}{ARRAY}}) {
    $subnode->_unlink();
  }

  system("rm -rf " . $self->get_the_name) if ($self->get_the_name);
  *{$self} = \undef;
  *{$self} = [];
  return undef;
}

1;
