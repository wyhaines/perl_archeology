#!/usr/bin/perl -wc
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: Metadata.pm

=head1

I<REVISION: .1>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: 14 Jun 2001>

=head1 PURPOSE:

Provides an interface into the data warehouse metadata files being
created by bkeydel's scripts.

=head1 EXAMPLE:

=head1 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################'

package Enigo::Products::Quetl::Metadata;

use Enigo::Common::Exception qw(:IO);
use Enigo::Common::ParamCheck qw(paramCheck);
use DBI;

use strict;
use vars qw($AUTOLOAD);

$Enigo::Products::Quetl::Metadata::VERSION = '.1';


######################################################################
##### Constructor: new
######################################################################

=pod

=head2 CONSTRUCTOR_NAME: new

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 14 Jun 2001>

=head2 PURPOSE:

Creates a new metadata reader.  This reader allows one to treat
the metadata file as a relational database table, allowing data
access via select statements.  The standard field names are
assumed to be:

  source
  date
  identifier
  type
  value

A metadata object provides transparent access to all of the normal
DBI database handle methods.

=head2 ARGUMENTS:

Optionally takes the filepath to the metadata file or a hashref
with a single argument, FILE, which points to the filepath.

=head2 THROWS:

=head2 RETURNS:

A hash reference blessed as a Metadata object. 

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
  my $self  = {};
  bless ($self, $class);
  $self->_init(@_);
  return $self;
}


######################################################################
##### Method: _init
######################################################################

=pod

=head2 METHOD_NAME: _init

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 14 Jun 2001>

=head2 PURPOSE:

Does initialization of the object.

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

sub _init {
  my $self = shift;
  my ($param) = paramCheck([FILE => 'U'],@_);

  if (defined $param->{FILE}) {
    $self->open({FILE => $param->{FILE}});
  }

}


######################################################################
##### Method: open
######################################################################

=pod

=head2 METHOD_NAME: open

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 14 Jun 2001>

=head2 PURPOSE:

Opens a metadata file for access.

=head2 ARGUMENTS:

Optionally takes the filepath to the metadata file or a hashref
with a single argument, FILE, which points to the filepath.

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

sub open {
  my $self = shift;
  my ($param) = paramCheck([FILE => 'U'],@_);

#  open(INDB,"<$param->{FILE}");
#  unlink "/tmp/meta_db_$$" if -e "/tmp/meta_db_$$";
#  $self->{TMPDB} = "meta_db_$$";
#  open(TMPDB,">/tmp/meta_db_$$");

    # use | as the default separator
#   my $separator = '[|]';
#   my $hdr_written = 0;

#  while (my $line = <INDB>) {

#       if($line =~ /^#FieldDelimiter:/)
#       {
#           chomp $line;
#           $line =~ s{^#FieldDelimiter:(.*)$}{$1};
#           $separator = "[${line}]";
#       }
#       elsif($line =~ /^#Format:/ and not $hdr_written)
#       {
#           chomp $line;
#           $line =~ s{^#Format:(.*)$}{$1};
#
#           $line =~ s{$separator}{,}g;
#       print TMPDB "${line}\n";
#           $hdr_written++;
#       }
#       else
#       {
#           if(not $hdr_written)
#           {
#               $hdr_written++;
#               print TMPDB "source,date,identifier,type,value\n"
#           }
#
#       $line =~ s{$separator}{,}g;
#       print TMPDB $line;
#       }
#  }
#  close INDB;
#  close TMPDB;
  
  $self->close() if defined($self->{DBH});
  $self->{DBH} = DBI->connect("DBI:CSV:f_dir=/tmp;csv_eol=\n");
}


######################################################################
##### Method: close
######################################################################

=pod

=head2 METHOD_NAME: close

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 14 Jun 2001>

=head2 PURPOSE:

Closes an opened metadata file.

=head2 ARGUMENTS:

none

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

sub close {
  my $self = shift;
  unlink "/tmp/meta_db_$$" if -e "/tmp/meta_db_$$";
  $self->disconnect(@_);
}


######################################################################
##### Method: prepare
######################################################################

=pod

=head2 METHOD_NAME: prepare

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 14 Jun 2001>

=head2 PURPOSE:

Overrides the DBI prepare statement so that it can intercept the SQL
statement being prepared.  Because the metadata file is massaged a
bit before access is provided to it, there is a temporary file created
in /tmp that contains this massaged data.  The name of this file, and
hence, the "tablename" of the metadata table, is an unknown element
to the user of the class.  So, use [!--table--] in the SQL statement
whereever one would normally use a table name, and that will silently
be replaced by the correct value to access the data.

=head2 ARGUMENTS:

As the DBI prepare().

=head2 THROWS:

=head2 RETURNS:

=head2 EXAMPLE:

my $sth = $md->prepare('select identifier from [!--table--]');

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub prepare {
  my $self = shift;
  my $sql = shift;
  $sql =~ s{\[!--logfile--\]}{$self->{FILE}}g;
  $self->{DBH}->prepare($sql,@_);
}


sub AUTOLOAD {
  my $self = shift;
  my $name = $AUTOLOAD;
  $name =~ s/.*:://;

  return $self->{DBH}->$name(@_);
}


sub DESTROY {
#  unlink "/tmp/meta_db_$$" if -e "/tmp/meta_db_$$";
}
1;
