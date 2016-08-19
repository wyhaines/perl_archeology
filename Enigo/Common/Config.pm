#!/usr/bin/perl -wc
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: Config.pm

=head1

I<REVISION: $Revision: 1.1.1.1 $>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: $Date: 2001/12/17 02:28:37 $>

=head1 PURPOSE:

Provides a common interface for interacting with configuration files
with a simple, generic syntax suitable for parsing in languages other
than Perl if needed (i.e. Java or C(++)).

The structure of this system requires one of more I<config catalog>
files which contain name value pairs, one per line, where the name
is the label of a configuration file, and the value is the path to
that configuration file.  Configuration values can then be L<"read()">
from one or more of the configurations specified in the B<config
catalog>.

=head1 EXAMPLE:

=head1 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

package Enigo::Common::Config;

use strict;
use vars qw($AUTOLOAD @ISA);
use Fcntl qw(:DEFAULT :flock);
use IO::File;
use Enigo::Common::Exception qw(:IO :general);
use Enigo::Common::Filter qw(Config);
use Enigo::Common::MethodHash;

@ISA = qw(Enigo::Common::MethodHash);

($Enigo::Common::Config::VERSION) =
   '$Revision: 1.1.1.1 $' =~ /\$Revision:\s+([^\s]+)/;#'


######################################################################
##### Constructor: new
######################################################################

=pod

=head2 CONSTRUCTOR_NAME: new

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 15 Mar 2000>

=head2 PURPOSE:

=head2 new

Returns a new object of type I<Enigo::Common::Config>.  B<new()>
takes no arguments and can be called as both an object method and
a class method.

=head2 ARGUMENTS:

none

=head2 THROWS:

nothing

=head2 RETURNS:

A blessed hash.

=head2 EXAMPLE:

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub new {
  my ($proto) = shift;
  my ($class) = ref($proto) || $proto;
  my ($self) = Enigo::Common::MethodHash->new();
  bless($self,$class);
  $self->_init();
  return $self;
}



######################################################################
##### Method: _init
######################################################################

=pod

=head2 METHOD_NAME: _init

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 15 Mar 2000>

=head2 PURPOSE:

This is a private method that initializes some data structures
for the object.

=head2 ARGUMENTS:

none

=head2 THROWS:

nothing

=head2 RETURNS:

undef

=head2 EXAMPLE:

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub _init {
  my ($self) = shift;
  $self->{LIBRARY_PATHS} = [];
  $self->{CATALOG} = {};
  $self->{CONFIG} = {};
  $self->{CONFIG_PATH} = '';
  $self->{VISITED_CONFIGS} = {};
  return undef;
}



######################################################################
##### Method: parse
######################################################################

=pod

=head2 METHOD_NAME: parse

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 15 Mar 2000>

=head2 PURPOSE:

Parses the I<catalog> file(s) to determine which configuration files are
available.  Takes a list of filenames to use as I<catalog> files.  The
format of the I<catalog> files is simple:

=over 4

=item *

Empty lines are skipped.

=item *

'#' marks a comment.  It and all characters following it on a line are ignored.

=item *

I<Catalog> entries are in LABEL = PATH format.  i.e. FOO = /etc/foo/conf.conf

=back

=head2 ARGUMENTS:

=head2 THROWS:

=head2 RETURNS:

=head2 EXAMPLE:

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub parse {
  my ($self) = shift;
  my @filenames = @_;

  foreach my $t (@filenames) {
    throw Enigo::Common::Exception::IO::File::NotFound($t)
      unless (-e $t);
    push(@{$self->{LIBRARY_PATHS}},$t);
    my ($fh) = new IO::File($t,'r') ||
      throw Enigo::Common::Exception::IO::File::NotReadable($t);
    flock($fh,LOCK_SH) ||
      throw Enigo::Common::Exception::IO::File::NotLockable($t);
    my @conditions;
    my $line;
    while ($line = <$fh>) {
      my $parseable;
      if ($line =~ /^([^\#]+)/) {
    $parseable = $1;
      } else {
    next;
      }

      next unless ($parseable =~ /^\s*(.+)\s*=\s*(.*)$/);
      my ($label) = $1;
      my ($path) = $2;
      $label =~ s/^\s*//;
      $label =~ s/\s*$//;
      $path =~ s/^\s*//;
      $path =~ s/\s*$//;
      next unless (-e $path);
      $self->{CATALOG}{$label} = $path;
    }
    flock($fh,LOCK_UN) ||
      throw Enigo::Common::Exception::IO::File::NotUnlockable($t);
    $fh->close() ||
      throw Enigo::Common::Exception::IO::File::NotCloseable($t);
  }
}



######################################################################
##### Method: return_catalog_list
######################################################################

=pod

=head2 METHOD_NAME: return_catalog_list

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 15 Mar 2000>

=head2 PURPOSE:

Returns an array containing all of the I<configuration> labels in
the I<catalog>.

=head2 ARGUMENTS:

none

=head2 THROWS:

nothing

=head2 RETURNS:

An array containing all of the configuration labels in the catalog.

=head2 EXAMPLE:

  my @labels = $config->return_catalog_list();

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub return_catalog_list {
  my ($self) = shift;
  return keys(%{$self->{CATALOG}});
}



######################################################################
##### Method: return_catalog
######################################################################

=pod

=head2 METHOD_NAME: return_catalog

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 15 Mar 2000>

=head2 PURPOSE:

Returns a hash that contains the I<configuration file catalog>.

=head2 ARGUMENTS:

none

=head2 THROWS:

nothing

=head2 RETURNS:

A hash that contains the configuration file catalog.

=head2 EXAMPLE:

  my %catalog = $config->return_catalog;

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub return_catalog {
  my ($self) = shift;
  return %{$self->{CATALOG}};
}



######################################################################
##### Method: return_library_paths
######################################################################

=pod

=head2 METHOD_NAME: return_library_paths

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 15 Mar 2000>

=head2 PURPOSE:

Returns an array containing the paths to all of the I<catalog> files
that have been read.

=head2 ARGUMENTS:

none

=head2 THROWS:

nothing

=head2 RETURNS:

An array containing the paths to all of the catalog files that have
been read.

=head2 EXAMPLE:

  my @paths = $config->return_library_paths();

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub return_catalog_paths {
  my ($self) = shift;
  return @{$self->{LIBRARY_PATHS}};
}



######################################################################
##### Method: read
######################################################################

=pod

=head2 METHOD_NAME: read

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 15 Mar 2000>

=head2 PURPOSE:

Takes as arguments a list of I<configuration file labels> and parses
each, in turn, for configuration settings.

The format is simple:

=over 4

=item *

C<NAME = VALUE>

=item *

C<set NAME = VALUE>

=item *

C<NAME>

(equivalent to C<NAME = 1>)

=item *

C<NAME on>

(equivalent to C<NAME = 1>)

=item *

C<NAME off>

(equivalent to C<NAME = 0>)

=item *

C<env NAME = VALUE>

(sets the name/value pair in the environment of the executing process)

=back

=head2 ARGUMENTS:

An array containing the labels of configuration files to read.

=head2 THROWS:

  Enigo::Common::Exception::Config::UndefinedConfiguration
  Enigo::Common::Exception::IO::File::NotFound

=head2 RETURNS:

undef

=head2 EXAMPLE:

  $config->read('MyConfig');

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub read {
  my ($self) = shift;
  my @config_names = @_;
  my $config_name;

  for (my $i = 0; $i <= $#config_names; $i++) {
    $config_name = $config_names[$i];
    next if $self->{VISITED_CONFIGS}{$config_name};
    require Enigo::Common::Exception::Config::UndefinedConfiguration &&
      throw
    Enigo::Common::Exception::Config::UndefinedConfiguration($config_name)
        unless (defined($self->{CATALOG}{$config_name}));

    $self->{VISITED_CONFIGS}{$config_name}++;
    my ($config_path) = $self->{CONFIG_PATH} = $self->{CATALOG}{$config_name};
    throw Enigo::Common::Exception::IO::File::NotFound($config_path)
      unless (-e $config_path);

    $self->_actual_read($config_path)
  }

  return undef;
}



######################################################################
##### Method: _actual_read
######################################################################

=pod

=head2 METHOD_NAME: _actual_read

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 15 Mar 2000>

=head2 PURPOSE:

Private method that takes care of the actual process of reading
a configuration file.

=head2 ARGUMENTS:

Takes as a scalar argument the path to a configuration file to
read.

=head2 THROWS:

  Enigo::Common::Exception::IO::File::NotReadable
  Enigo::Common::Exception::IO::File::NotLockable
  Enigo::Common::Exception::IO::File::NotUnloackable
  Enigo::Common::Exception::IO::File::NotCloaseable

=head2 RETURNS:

undef

=head2 EXAMPLE:

  $config->read('MyConfig');

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub _actual_read {
  my ($self) = shift;
  my ($config_path) = shift;
  my ($fh) = new IO::File($config_path,'r') ||
    throw Enigo::Common::Exception::IO::File::NotReadable($config_path);
  flock($fh,LOCK_SH) ||
    throw Enigo::Common::Exception::IO::File::NotLockable($config_path);
  my @conditions;
  while (my $line = <$fh>) {
    next unless ($line =~ /^([^\#]+)/);
    $line = $1;
    my ($n,$v,$t);

    if ($line =~ /^\s*\%if\s+(.*)$/i) {
      push @conditions,$1;
      next;
    }

    if ($line =~ /^\s*\%elsif\s+(.*)$/i) {
      pop @conditions;
      push @conditions,$1;
      next;
    }

    if ($line =~ /^\s*\%else/i) {
      my $condition = pop @conditions;
      my $condition = "!&{sub{$condition}}";
      push @conditions,$condition;
      next;
    }

    if ($line =~ /^\s*\%fi/i) {
      pop @conditions;
      next;
    }

    my $bailout_flag = 0;
    if (@conditions) {
      #####
      #// What conditions do we support?  I figure that it's easiest to stick with straight
      #// forward Perl statements that are simply evaluated.  However, some regex
      #// substitution facilities should be provided to make it easy to reference some
      #// common data items that may not necessarily be part of the environment.
      #// hostname.
      foreach my $condition (@conditions) {
        $condition = Enigo::Common::Filter->filter($condition);
        my $value = eval "$condition";
        unless ($value) {
          $bailout_flag++;
          last;
        }
      }
      next if $bailout_flag;
    }

    if ($line =~ /^\s*include\s+(\S+)\s*$/i) {
      my $include = $1;
      $include =~ s/\$\{(\w+)\}/$ENV{$1}/ge;
      if ($self->{VISITED_CONFIGS}{$include}) {
    next;
      } else {
    $self->read($include);
    next;
      }
    } elsif ($line =~ /^\s*(\w+)\s*$/) {
      $t = 0;
      $n = $1;
      $v = 1;
    } elsif ($line =~ /^\s*(\w*)\s+(on|off)\s*$/i) {
      $t = 0;
      $n = $1;
      if ($2 =~ /on/i) {
    $v = 1;
      } else {
    $v = 0;
      }
    } elsif ($line =~ /^\s*(\w+)\s*=\s*(.*)$/ or
         $line =~ /^\s*set\s*(\w+)\s*=\s*(.*)$/i) {
      $t = 0;
      $n = $1;
      $v = $2;
    } elsif ($line =~  /^\s*env\s*(\w+)\s*=\s*(.*)$/i) {
      $t = 1;
      $n = $1;
      $v = $2;
    } else {
      next;
    }

    if ($t) {
      $ENV{$n} = $v;
    } else {
      if (defined $self->{CONFIG}->{$n} and
          ref($self->{CONFIG}->{$n}) ne 'ARRAY') {
        $self->{CONFIG}->{$n} = [$self->{CONFIG}->{$n},$v];
      } elsif (defined $self->{CONFIG}->{$n} and
          ref($self->{CONFIG}->{$n}) eq 'ARRAY') {
        push(@{$self->{CONFIG}->{$n}},$v);
      } else {
        $self->{CONFIG}->{$n} = $v;
      }
    }
  }
  flock($fh,LOCK_UN) ||
    throw Enigo::Common::Exception::IO::File::NotUnlockable($config_path);
  close($fh) ||
    throw Enigo::Common::Exception::IO::File::NotCloseable($config_path);
}



######################################################################
##### Method: get
######################################################################

=pod

=head2 METHOD_NAME: get

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 15 Mar 2000>

=head2 PURPOSE:

The the value of some configuration item.

=head2 ARGUMENTS:

Takes as a scalar argument the name of the configuration item for
which a value is to be retrieved.  Returns an undef value if an
attempt is made to retrieve an item which has not been read
(maybe this should throw some sort of exception in that case,
instead?).

The get method can also be called implicitly in a config object
by simply referencing the parameter to get as a method name.  So long
as that name does not correspond to a real method, and no parameters
are passed in the method call, it will be assumed to be a get for a
parameter of the same name as the method call.

=head2 THROWS:

nothing

=head2 RETURNS:

A scalar value.

=head2 EXAMPLE:

  my $dsn = $config->get('DSN');

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub get {
  my ($self) = shift;
  my ($config_name) = shift;
  return $self->{CONFIG}{$config_name};
}



######################################################################
##### Method: get_names
######################################################################

=pod

=head2 METHOD_NAME: get_names

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 15 Mar 2000>

=head2 PURPOSE:

Returns an array containing the names of all of the configuration
items that have been read.

=head2 ARGUMENTS:

none

=head2 THROWS:

nothing

=head2 RETURNS:

An array containing the names of all of the configuration items.

=head2 EXAMPLE:

  my @names = $config->get_names();

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub get_names  {
  my ($self) = shift;
  return keys(%{$self->{CONFIG}});
}



######################################################################
##### Method: get_as_hash
######################################################################

=pod

=head2 METHOD_NAME: get_as_hash

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 15 Mar 2000>

=head2 PURPOSE:

Returns all of the configuration items which have been read via a
hash, with keys of the configuration item names and values of
the corresponding configuration item values.

=head2 ARGUMENTS:

none

=head2 THROWS:

nothing

=head2 RETURNS:

A hash containing all of the configuration items which have been
read.

=head2 EXAMPLE:

  my %CONFIG = $config->get_as_hash();

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub get_as_hash {
  my ($self) = shift;
  return %{$self->{CONFIG}};
}



######################################################################
##### Method: reset
######################################################################

=pod

=head2 METHOD_NAME: reset

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 15 Mar 2000>

=head2 PURPOSE:

Wipes out all previously read configuration items in the config
object.  This clears the slate so that a new set of configuration
items can be read.

=head2 ARGUMENTS:

none

=head2 THROWS:

nothing

=head2 RETURNS:

undef

=head2 EXAMPLE:

  $config->reset();

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub reset {
  my ($self) = shift;
  $self->{CONFIG} = {};
  $self->{LIBRARY_PATHS} = [];
  $self->{VISITED_CONFIGS} = {};
  $self->{CONFIG_PATH} = undef;
  return undef;
}


sub AUTOLOAD {
  my ($key) = $AUTOLOAD =~ /.*::(.*)/;
  my $self = shift;

  unless (@_) {
    return $self->{CONFIG}->{$key};
  }

  if (scalar(@_) == 1) {
    $self->{CONFIG}->{$key} = $_[0];
    return $self;
  } else {
    $self->{CONFIG}->{$key} = [@_];
    return $self;
  }
}

1;
