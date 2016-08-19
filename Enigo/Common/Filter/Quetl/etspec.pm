#!/usr/bin/perl
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: $RCSfile: etspec.pm,v $

Z<>

I<REVISION: $Revision: 1.1.1.1 $>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: $Date: 2001/12/17 02:28:37 $>

=head1 PURPOSE:

Takes an XML description of source and destination data items,
the fields of interest, and transformations to conduct on those
fields, and turns it all into Perl code which will "make it so."

The bulk of most ETL type tasks should be possible to implement
using this XML description.

=head1 DESCRIPTION:

The E<lt>ETSPECE<gt> XML language is use to define ETL tasks
using a fairly small set of tags, applied in a fixed pattern.
All ETL tasks have X basic sections:

  Define a data source
    Define input record rejection rules
    Define input fields
  Define data destinations
  Define a source processing block
    Define supplementary fields
    Write any needed transformations
    Define an outrecord.
      Define output record rejection rules
      Describe output fields

Each of those sections has a few XML tags specific to that
section which are used to define the section.  Below is an
explanation of each of these.

B<Define a Data Source>

This is the first thing that must be defined, for without input
data, none of the rest of the actions have any purpose.

=over 4

=item E<lt>source name="N" field_delim="," record_delim="\n" source="S"E<gt>

The E<lt>sourceE<gt> tag initiates a data source definition.  It takes several
attributes, C<name>,C<source>,C<field_delim>, and C<record_delim>.  Of these,
C<name> and C<source> are mandatory, while C<field_delim> and C<record_delim>
each have default values if none are provided.

=over 4

=item name

Each data source must be given a name so that it can be refered to
from other XML tags.  This is C<name>.

=item source

Integral to each data source is, of course, what the source of
data actually is.  This information is provided via the C<source>
attribute.  The E<lt>ETSPECE<gt> compiler knows about a number of
different types of data sources, including Perl variables
(scalars or arrays), database tables, urls, or files.

=over 4

=item scalar/array variable data source

If there is perl code that does some preprocessing/prereading of
data, and if the data is placed either within a scalar variable
or within an array variable (one line per element of the array),
this data can be used as an E<lt>ETSPECE<gt> data source.
To specify this, use the following syntax for the attribute:

  source="$foo"
  source="@bar"

=item database table data source

A database table can be used as a data source.  To do this, the s
source should be set similarly to a standard perl DBI connect
string.  The general format is:

  dbi:VENDOR:USER/PASSWORD@DATABASE

=over 4

=item VENDOR

This is the type of database, and should correspond to the naming
of the relevant Perl database driver.  Some valid values for this
are: C<Oracle>, C<CSV>, C<Excel>, C<ODBC>, and C<SQLite>.  This
is only a very small sampling of the available database drivers,
however.

=item USER

Pretty self explanatory.  This is the username to use when logging
into the database.

=item PASSWORD

Likewise self explanatory, this is the password to use to
authenticate against the database.

=item DATABASE

This should be a value that identifies the database to connect to.
The exact value of this will differ, depending on they type of
database being connected to.  One should look at the documentation
for the given driver (i.e. DBD::Oracle, or DBD::CSV, or whatever)
to determine what the appropriate manner to set this is.

=back

A few examples of valid C<source> attributes are:

  source="dbi:Oracle:greased/throwoutbearing@lightning"
  source="dbi:SQLite:/@/var/log/RPCServer/db"

=item url request data source

If the value of the C<source> attribute appears to be a URL of
some flavor, it will be treated as such.  i.e.

  source="http://feeds.enigo.com/equities/today.csv"
  source="ftp://ftp.fancysuite.com/incoming"

=item file based data source

The final supported type of data source is a file.  This can be
a statically named file, or the name of the file can be delivered
within a scalar variable.  The data source specification format
for a filename is:

  source="filename:FILENAME"

where filename is either a statically named file, or is a scalar
variable.  For example:

  source="filename:/var/log/messages"
  source="filename:$logfile"

=back

=item field_delim

The delimiter between fields, if the input source is some sort
of a delimited source.  This is an optional attribute as it
defaults to a comma (",").

=item record_delim

The delimiter between records if the input source is some sort
of a delimited source.  This is an optional attribute as it
defaults to a newline ("\n").

=back

=head1 EXAMPLE:


=head1 TODO:

  * Make it so that any element of data within a source can be
    specified within a scalar variable.  For example, a URL could
    be constructed within a scalar variable, and the code would
    be smart enough to look at the value of this scalar, determine
    that it is a URL data source, and then use that value
    appropriately.

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

package Enigo::Common::Filter::Quetl::etspec;

$Enigo::Common::Filter::Quetl::etspec::VERSION =
  '$Revision: 1.1.1.1 $' =~ /\$Revision:\s+([^\s]+)/;#'

use XML::Parser::PerlSAX;
use XML::Grove;
use XML::Grove::Builder;
use IO::Scalar;
use IO::ScalarArray;
use LWP::UserAgent;
use Term::ANSIColor;
use Data::Dumper;

use Enigo::Common::ParamCheck qw(paramCheck);
use Enigo::Common::Exception;
use Enigo::Common::Exception::General;

sub filter {
  my $self = shift;
  my $code = shift;
  my $static_code = $code;
  my $builder = XML::Grove::Builder->new();
  my $parser = XML::Parser::PerlSAX->new(Handler => $builder);

  #A few initial notes:
  #The code that this builds will setup a number of variables for
  #keeping track of sources, destinations, fields, processing loops,
  #and all of the various goodies required to make it all work.
  #The intent is that this filter will write decently structured
  #and efficient Perl that should work with whatever other code
  #surrounds what this module builds.  To help to prevent namespace
  #collisions, we'll try to keep things within local scopes via
  #the liberal use of {} blocks, and for things that need to
  #persist for a while, they will all be named starting with
  #'__etspec_'.

  #tiny note: I should break this parsing up into subroutines
  #so that it's easier to read.

  my $etspec_count = 1;

  while ($code =~
     s/(<etspec>.*?<\/etspec>)/<!--__etspec_replace_$etspec_count-->/is) {
    my $etspec = $1;
    my $newcode;
    my $sources = {}; #stores info on configured sources
    my %flags;
    my $infields = [{}];
    my $destinations = {}; #stores info on configured destinations
    my $processes = {}; #stores info on source processing loops

    $etspec =~ s/\\\]\\\]\\>/\]\]>/g;
    $etspec = join("\n",
           '<?xml version="1.0"?>',
           $etspec);
    my $grove;
    eval {
      $grove = $parser->parse(Source => {String => $etspec});
    };

    if ($@) {
      my $error_text = $@;
      my ($line) = $@ =~ / at line (\d+)/;
      my $zero_adjusted_line = $line - 1;
      my $first_context_line =
    $zero_adjusted_line > 4 ? $zero_adjusted_line - 5 : 0;
      my $first_context_count =
    $first_context_line ? 5 : $zero_adjusted_line;
      my $text;

      my $regexp = '^';
      $regexp .= '(?:[^\n]*\n){' . $first_context_line . '}'
    if ($first_context_line > 0);
      $regexp .= '?(' . '[^\n]*\n' x $first_context_count;
      $regexp .= ')([^\n]*(?:\n|$))(' . '[^\n]*(?:\n|$)' x 2;
      $regexp .= ')';
      $etspec =~ /^$regexp/m;
      my $first_context = $1;
      my $line = $2;
      my $last_context = $3;
      $text = join('',
           "Error: XMLParser: $@\n",
           $1,
           color('bold'),
           $2,
           color('reset'),
           $3,
           "\n");
      print STDERR $text;
      exit();
    }


    foreach my $item (@{$grove->{Contents}}) {
      next unless (ref($item) !~ /XML::Grove::Characters/);

      #This should always be matched right away.
      if (ref($item) =~ /::Element/ and
      $item->{Name} =~ /^etspec$/i) {
    #Now we start searching through the <etspec> contents to
    #find all of the good stuff.
    foreach my $etspec_item (@{$item->{Contents}}) {
      #Match a source tag and, if necessary, write the code to
      #access the source.  If the source name looks like either
      #a scalar variable or an array, it is assumed that an
      #already defined variable of that type is the source.
      #Otherwise, the source name is assumed to be
      #be a URL.  It the URL is lacking a resource type
      #identifier (http://, ftp://, file://, etc...), it is
      #assumed to be a file specifier.
      if (ref($etspec_item) =~ /::Element/ and
          $etspec_item->{Name} =~ /^source$/i) {
        my $etspec;
        my $name = $etspec_item->{Attributes}->{name};
        my $field_delim = $etspec_item->{Attributes}->{field_delim};
        my $record_delim = $etspec_item->{Attributes}->{record_delim};
        my $source = $etspec_item->{Attributes}->{source};

        #First, record information about the source.
        $sources->{$name}->{name} = $name;
        $sources->{$name}->{field_delim} = defined $field_delim ?
          qq($field_delim) : ',';
        $sources->{$name}->{record_delim} = defined $record_delim ?
          qq($record_delim) : "\n";
        $sources->{$name}->{source} = $source;
        unless ($flags{'++s_initialized++'}) {
          $flags{'++s_initialized++'}++;
          $sources->{$name}->{code} = <<ECODE;
#There is a _boatload_ of optimization that can be done to this generated
#code.  Massive performance increases can be found.
#\$SIG{__DIE__} = \\&die_handler;
use IO::File;
use IO::Scalar;
use IO::ScalarArray;
use LWP::UserAgent;
use Enigo::Common::Exception::General;
use DBI;
my \%__etspec_sources = ();
my \$__etspec_infields = [{}];
my \%__etspec_transform_code;
my \%__etspec_reject_code;
my \$__etspec_ua;

sub index_field {
  #record
  #delimiter
  #index
  #content
  my (\$record,\$delimiter,\$index,\$content) = \@_;

  my \$delimiter_pattern = \$delimiter;
  \$delimiter_pattern =~ s/(.)/\\\\\$1/g;
  my \@fields = split(/\$delimiter_pattern/,\$record);

  if (\$index < 0) {
    \$fields[scalar(\@fields)] = \$content;
  } else {
    \$fields[\$index] = \$content;
  }

  return join(\$delimiter,\@fields);
}

ECODE
        }
            $sources->{$name}->{code} .= <<ECODE;
\$__etspec_sources{$name}->{name} = q($name);
\$__etspec_sources{$name}->{field_delim} = q($field_delim) ?
  q($field_delim) : ',';
\$__etspec_sources{$name}->{record_delim} = q($record_delim) ?
  q($record_delim) : "\\n";
\$__etspec_sources{$name}->{source} = q($source);
ECODE
        #Then write the code to access the source.
        if ($source =~ /^\$/) {
          $sources->{$name}->{code} .= <<ECODE;
\$__etspec_sources{$name}->{handle} = IO::Scalar->new(\\$source);
ECODE
              $sources->{$name}->{type} = 'Scalar';
        } elsif ($source =~ /^\@/) {
          $sources->{$name}->{code} .= <<ECODE;
\$__etspec_sources{$name}->{handle} = IO::ScalarArray->new(\\$source);
ECODE
              $sources->{$name}->{type} = 'Array';
        } elsif ($source =~ /^dbi:/i) {
          #Write out to a database.
          $sourcess->{$name}->{code} .= <<ECODE;
my \$spec = qq($source);
my (\$vendor,\$user,\$auth,\$sid,\$commit_interval) =
  \$spec =~ m{^dbi:(\\w+):([^/]+)/([^\\\@]*)\\\@(\\w+):(\\d+)}i;
my \$attr = \$commit_interval ?
  {AutoCommit => 0,RaiseError => 1,PrintError => 0} :
  {AutoCommit => 1,RaiseError => 1,PrintError => 0};
\$__etspec_sources{$name}->{handle} =
  [DBI->connect("dbi:\$vendor:\$sid",qq(\$user),qq(\$auth),\$attr),
   q(\$commit_interval)];
              $sources->{$name}->{type} = 'DB';
ECODE
        } elsif ($source =~ /^\w:\/\//) {
          $sources->{$name}->{code} .= <<ECODE;
\$__etspec_ua = new LWP::UserAgent;
my \$request = HTTP::Request->new(POST => q($source));
my \$response = \$__etspec_ua->request(\$request);

unless (\$response->is_success) {
  throw Enigo::Common::Exception::General
    ({TYPE => 'UARequestFailed',
      TEXT => "User Agent Request for source \$source failed."});
  }
my \$response_content = \$response->content;

\$__etspec_sources{$name}->{handle} = IO::Scalar->new(\\\$response_content);
ECODE
              $sources->{$name}->{type} = 'Scalar';
            } else {
          $sources->{$name}->{code} .= <<ECODE;
print STDERR "Source: ",q($source),"\n";
my \$source_file = q($source);
if (q($source) =~ /^filename:\s*\\\$(.+)\$/) {
  \$source_file = \${\$1};
}

my \$file_handle;
unless (\$file_handle = IO::File->new(\$source_file,'r')) {
  throw Enigo::Common::Exception::General
    ({TYPE => 'UARequestFailed',
      TEXT => "User Agent Request for \$source_file failed."});
 }
\$__etspec_sources{$name}->{handle} = \$file_handle;
ECODE
              $sources->{$name}->{type} = 'File';
        }
        foreach my $source_item (@{$etspec_item->{Contents}}) {
          next unless (ref($source_item_item) !~ /XML::Grove::Characters/);

          #Found a rejection field.
          if (ref($source_item) =~ /::Element/ and
          $source_item->{Name} =~ /^reject$/i) {
        my $regex = join('',map {$_->{Data}}
                 @{$source_item->{Contents}});
        $regex =~ s/^\s*(.*?)\s*$/$1/s;
        push @{$sources->{$name}->{rejects}},qq($regex);
          }

          #Yee Haw!  A field in the incoming source is being defined.
          if (ref($source_item) =~ /::Element/ and
          $source_item->{Name} =~ /^infield$/i) {
        my $infield = {input_field => 1};
        $infield->{name} = $source_item->{Attributes}->{name};
        
        foreach my $infield_item (@{$source_item->{Contents}}) {
          next unless (ref($infield_item) !~ /XML::Grove::Characters/);

          if (ref($infield_item) =~ /::Element/ and
              $infield_item->{Name} =~ /^regex$/i) {
            $infield->{regex} = join('',map {$_->{Data}}
                         @{$infield_item->{Contents}});
            $infield->{regex} =~ s/^\s*//;
            $infield->{regex} =~ s/\s*$//;
          } elsif (ref($infield_item) =~ /::Element/ and
               $infield_item->{Name} =~ /^position$/i) {
            $infield->{position}->{index} =
              $infield_item->{Attributes}->{index};
            $infield->{position}->{start} =
              $infield_item->{Attributes}->{start};
            $infield->{position}->{length} =
              $infield_item->{Attributes}->{length};
          }
        }
        
        $sources->{$name}->{code} .= <<ECODE;
push(\@{\$__etspec_infields},
  {name => q($infield->{name}),
   regex => q($infield->{regex}) ne '' ? q($infield->{regex}) : undef,
   index => q($infield->{position}->{index}) =~ /^\\d+\$/ ?
     q($infield->{position}->{index}) : undef,
   start => q($infield->{position}->{start}) =~ /^\\d+\$/ ?
     q($infield->{position}->{start}) : undef,
   length => q($infield->{position}->{length}) =~ /^\\d+\$/ ?
     q($infield->{position}->{length}) : undef,
   input_field => 1,
   value => undef});
\%{\$__etspec_infields->[0]}->{$infield->{name}} = \$\#{\$__etspec_infields};
ECODE
        $sources->{$name}->{infields}->{$infield->{name}} = $infield;
        push @{$infields},$infield;
        %{$infields->[0]}->{$infield->{name}} = $#{$infields};
          }
        }
        $newcode .= $sources->{$name}->{code};
        next;
      }

      #Match a destination tag and write the code to
      #access the destination.  If the destination name is preceded by a
      #dollar ($) symbol, the it is taken to be an already
      #defined perl scalar variable.  Otherwise, it is assumed to
      #be a URL.  It the URL is lacking a resource type
      #identifier (http://, ftp://, file://, etc...), it is
      #assumed to be a file specifier.
      if (ref($etspec_item) =~ /::Element/ and
          $etspec_item->{Name} =~ /^destination$/i) {
        my $etspec;
        my $name = $etspec_item->{Attributes}->{name};
        my $field_delim = $etspec_item->{Attributes}->{field_delim};
        my $record_delim = $etspec_item->{Attributes}->{record_delim};
        my $destination = $etspec_item->{Attributes}->{destination};

        #First, record information about the destination.
        $destinations->{$name}->{name} = $name;
        $destinations->{$name}->{field_delim} = defined $field_delim ?
          q($field_delim) : ',';
        $destinations->{$name}->{record_delim} = defined $record_delim ?
          q($record_delim) : "\n";
        $destinations->{$name}->{destination} = $destination;
        unless ($flags{'++initialized++'}) {
          $flags{'++initialized++'}++;
          $destinations->{$name}->{code} = <<ECODE;
use IO::File;
use IO::Scalar;
use IO::ScalarArray;
use LWP::UserAgent;
use DBI;
use Enigo::Common::Exception::General;
my \%__etspec_destinations = ();

ECODE
        } else {
          $destinations->{$name}->{code} = <<ECODE;

ECODE
        }
            $destinations->{$name}->{code} .= <<ECODE;
\$__etspec_destinations{q($name)}->{name} = q($name);
\$__etspec_destinations{q($name)}->{field_delim} = q($field_delim) ?
  q($field_delim) : ',';
\$__etspec_destinations{q($name)}->{record_delim} = q($record_delim) ?
  q($record_delim) : "\\n";
\$__etspec_destinations{q($name)}->{destination} = q($source);
ECODE
        #Then write the code to access the destination.
        if ($destination =~ /^\$/) {
          #Write out to a scalar.
          $destinations->{$name}->{code} .= <<ECODE;
\$__etspec_destinations{q($name)}->{handle} = IO::Scalar->new(\\$destination);
ECODE
        } elsif ($destination =~ /^\@/) {
          #Write out to an array.
          $destinations->{$name}->{code} .= <<ECODE;
\$__etspec_destinations{q($name)}->{handle} = IO::ScalarArray->new(\\$destination);
ECODE
        } elsif ($destination =~ /^dbi:/i) {
          #Write out to a database.
          my ($partial, $commit_interval) =
        $destination =~ /^dbi:([^:]+)(?::(.*))?$/i;
          $commit_interval = 0 unless ($commit_interval);
          $destinations->{$name}->{code} .= <<ECODE;
if (ref($partial) =~ /DBI/) {
  \$__etspec_destinations{q($name)}->{handle} =
  [$partial,qq($commit_interval),undef,0];
} else {
  my \$spec = qq($destination);
  my (\$vendor,\$user,\$auth,\$sid,\$commit_interval) =
    \$spec =~ m{^dbi:(\\w+):([^/]+)/([^\\\@]*)\\\@(\\w+):(\\d+)}i;
  my \$attrib = \$commit_interval ?
    {AutoCommit => 0,RaiseError => 1,PrintError => 0} :
    {AutoCommit => 1,RaiseError => 1,PrintError => 0};
  eval {
    \$__etspec_destinations{q($name)}->{handle} =
    [DBI->connect("dbi:\$vendor:\$sid","\$user","\$auth",\$attrib),
    qq(\$commit_interval),undef,1];
  };
}
ECODE
        } elsif ($destination =~ /^\w:\/\// and
             $destination !~ /^file:/) {
          #Write out to a URL
          $destinations->{$name}->{code} .= <<ECODE;
my \$request = HTTP::Request->new(POST => "$destination");

\$__etspec_destinations{q($name)}->{handle} = $request;
ECODE
            } else {
          #Write out to a file.
          $destination =~ s/^file://;
          $destination =~ s|^/+|/|;
          $destinations->{$name}->{code} .= <<ECODE;
my \$file_handle;
my \$destination_file = q($destination);
if (q($destination) =~ /^filename:\s*\\\$(.+)\$/) {
  \$destination_file = \${\$1};
}
mkdirs({PATH => \$destination_file});
unless (\$file_handle = IO::File->new(\$destination_file,'a')) {
  throw Enigo::Common::Exception::General
    ({TYPE => 'UARequestFailed',
      TEXT => "user Agent Request for \$destination_file failed."});
 }
\$file_handle->autoflush(1);
\$__etspec_destinations{q($name)}->{handle} = \$file_handle;
ECODE
        }
        $newcode .= $destinations->{$name}->{code};
        next;
      }
      #The processing steps.
      if (ref($etspec_item) =~ /::Element/ and
          $etspec_item->{Name} =~ /^process$/i) {
        my $source = $etspec_item->{Attributes}->{source};
        $processes->{$source}->{name} = $source;
        $newcode .= <<ECODE;
\{
  local \$/ = \$__etspec_sources{$source}->{record_delim};
  my \$rdelim = \$/;
  my \$handle = \$__etspec_sources{$source}->{handle};
ECODE
            if ($sources->{$source}->{type} eq 'Scalar' or
                $sources->{$source}->{type} eq 'Array') {
          #The lazy bastard who wrote IO::Scalar and IO::ScalarArray
          #hasn't felt the need to make his code honor the $/ variable
          #that specifies the input record seperator, forcing me to
          #cobble something together to do it.  Let's pull out the
          #pom-poms and cheer.  :|
              $newcode .= <<ECODE;
  my \$total_lines = join('',(\$handle->getlines()));;
  pos(\$total_lines) = 0;
  while (\$total_lines =~ m{\\G(.*?(?:\$\/|\$))}gs) {
    my \$__etspec_inline = \$1;
  <__${source}__internals>
 \}
\}
ECODE
            } elsif ($sources->{$source}->{type} eq 'DB') {
          $newcode .= <<ECODE;
#Ja Ja.  We need some code here.
ECODE
            } else {
              $newcode .= <<ECODE;
  while (my \$__etspec_inline = <\$handle>) \{
  <__${source}__internals>
 \}
\}
ECODE
            }
        my $internals_code = "chomp \$__etspec_inline;\n";

            #Write the code to do the initial rejection of
            #lines;
            foreach my $reject_regex (@{$sources->{$source}->{rejects}}) {
          unless ($reject_regex =~ /^!/) {
        $internals_code .= <<ECODE;
next if (\$__etspec_inline =~ m{$reject_regex}s);
ECODE
          } else {
        $reject_regex = substr($reject_regex,1);
        $internals_code .= <<ECODE;
next if (\$__etspec_inline !~ m{$reject_regex}s);
ECODE
          }
            }

            #Write the code to extract each field in the source.
            foreach my $infield (keys %{$sources->{$source}->{infields}}) {
          next unless $infields->{$infield}->{input_field};
          $internals_code .= <<ECODE;
\{
  my \$datum = undef;
  if (defined \$__etspec_infields->{$infield}->{index}) {
    \$datum = 
      (split(/$sources->{$source}->{field_delim}/,\$__etspec_inline))
    [\$__etspec_infields->{$infield}->{index}];
  } else {
    \$datum = \$__etspec_inline;
  }

  if (defined \$__etspec_infields->{$infield}->{start}) {
    if (\$__etspec_infields->{$infield}->{start} > length(\$__etspec_inline)) {
      \$datum = '';
    } else {
      my \$read_length =
    ((\$__etspec_infields->{$infield}->{start} +
          \$__etspec_infields->{$infield}->{length}) <=
     length(\$__etspec_inline)) ?
       \$__etspec_infields->{$infield}->{length} :
         length(\$__etspec_inline) - \$__etspec_infields->{$infield}->{start};

      \$datum = substr(\$datum,
               \$__etspec_infields->{$infield}->{start},
               \$read_length);
    }
  }
  if (defined \$__etspec_infields->{$infield}->{regex}) {
    (\$datum) = (\$datum =~ /\$__etspec_infields->{$infield}->{regex}/);
  }

  \$__etspec_infields->{$infield}->{value} = \$datum;
\}
ECODE
            }
            foreach my $process_item (@{$etspec_item->{Contents}}) {
          next unless (ref($process_item) !~ /XML::Grove::Characters/);

          #Match an accessory field.  These are fields that can be used
          #as the targets of a transformation, but don't directly derive
          #from an input source.
          if (ref($process_item) =~ /::Element/ and
          $process_item->{Name} =~ /^field$/i) {
        my $name = $process_item->{Attributes}->{name};
        my $value = _field_interpolate
        ({INFIELDS => $infields,
          VALUE => $process_item->{Attributes}->{value}});
        $internals_code .= <<ECODE;
unless (exists \%{\$__etspec_infields->[0]}->{$name}) {
  push(\@{\$__etspec_infields},
    {name => q($name),
     regex => undef,
     index => undef,
     start => undef,
     length => undef,
     value => qq($value)});
  \%{\$__etspec_infields->[0]}->{$name} = \$\#{\$__etspec_infields};
} else {
  \$__etspec_infields->{$name}->{value} = qq($value);
}
ECODE
        push @{$infields},{name => q($name),
                   regex => undef,
                   index => undef,
                   start => undef,
                   length => undef,
                   value => q($value)};
        %{$infields->[0]}->{$name} = $#{$infields};
        
        next;
          }
          #Match a transform tag.  This should be fun.
          if (ref($process_item) =~ /::Element/ and
        $process_item->{Name} =~ /^transform$/i) {
        my $target = $process_item->{Attributes}->{target};
        my $transform = join('',map {$_->{Data}}
                     @{$process_item->{Contents}});
        $transform = _field_interpolate({INFIELDS => $infields,
                         VALUE => $transform});

        $internals_code .= <<ECODE;
unless (defined \$__etspec_transform_code{q($transform)}) {
  \$__etspec_transform_code{q($transform)} = sub {
$transform
  };
}

\$__etspec_infields->{$target}->{value} =
  eval{\&{\$__etspec_transform_code{q($transform)}}()};
ECODE

        $infields{$target}->{value} = $transform;
          }
          #Match an outrecord tag.
          if (ref($process_item) =~ /::Element/ and
          $process_item->{Name} =~ /^outrecord$/i) {
        my $outrecord =
          {DESTINATION =>
           $process_item->{Attributes}->{destination},
           REJECTS => [],
           FORMAT => [],
           VALUES => []};

        foreach my $outrecord_item (@{$process_item->{Contents}}) {
          next unless (ref($outrecord_item) !~ /XML::Grove::Characters/);

          if (ref($outrecord_item) =~ /::Element/ and
              $outrecord_item->{Name} =~ /^reject$/i) {
            my $regex = join('',map {$_->{Data}}
                     @{$outrecord_item->{Contents}});
            $regex =~ s/^\s*(.*?)\s*$/$1/s;
            $regex = _field_interpolate({INFIELDS => $infields,
                         VALUE => $regex});
            push @{$outrecord->{REJECTS}},qq($regex);
          }

          if (ref($outrecord_item) =~ /::Element/ and
              $outrecord_item->{Name} =~ /^field$/i) {
            my $field =
              {ALIAS => $outrecord_item->{Attributes}->{alias},
               INDEX => $outrecord_item->{Attributes}->{index},
               START => $outrecord_item->{Attributes}->{start},
               LENGTH => $outrecord_item->{Attributes}->{length},
               PAD => $outrecord_item->{Attributes}->{pad},
               PADCHAR => $outrecord_item->{Attributes}->{padchar},
               FORMAT => join('',map {$_->{Data}}
                      @{$outrecord_item->{Contents}})};
            $field->{FORMAT} =~ s/^\s*//s;
            $field->{FORMAT} =~ s/\s*$//s;
            push @{$outrecord->{FORMAT}},$field;
            push @{$outrecord->{VALUES}},[];

            foreach my $values_item (@{$outrecord_item->{Contents}}) {
              next unless (ref($values_item) !~ /XML::Grove::Characters/);

              if (ref($values_item) =~ /::Element/ and
              $values_item->{Name} =~ /^value$/i) {
            push @{$outrecord->{VALUES}->[$#{$outrecord->{VALUES}}]},
              $values_item->{Attributes}->{field};
              }
            }#
          }#Close values processing
        }#close outrecord subtag processing
        $internals_code .= <<ECODE;
my \$outrecord = undef;
\$outrecord = []
  if ref(\$__etspec_destinations{q($outrecord->{DESTINATION})}->{handle}) eq 'ARRAY';
ECODE
        for (my $index = 0;
             $index < scalar(@{$outrecord->{FORMAT}});
             $index++) {
          my $field = $outrecord->{FORMAT}->[$index];
          my @values = @{$outrecord->{VALUES}->[$index]};
          my $alias = $field->{ALIAS};
          my $value = join(',',map {"\$__etspec_infields->{q($_)}->{value}"}
                   @{$outrecord->{VALUES}->[$index]});
          if (defined $field->{INDEX}) {
            $internals_code .= <<ECODE;
my \$content;
if (q($field->{FORMAT})) {
  \$content = sprintf(q($field->{FORMAT}),$value);
} else {
  \$content = join('',$value);
}

if (q($field->{START}) ne '') {
  my \$len = q($field->{LENGTH}) ne '' ?
  q($field->{LENGTH}) :
  q($field->{START}) + length($content);
  my \$padc = q($field->{PADCHAR}) ? q($field->{PADCHAR}) : ' ';
  my \$blank;
  my \$start;
  if (q($field->{START}) < 0) {
    \$start = (q($field->{LENGTH}) + q($field->{START}));
  } else {
    \$start = q($field->{START});
  }
  if (q($field->{PAD})) {
    \$blank = \$padc x \$len;
  } else {
    \$blank = \$padc x (q($field->{START}) + length(\$content));
  }

  my \$replace_len =
    (q($field->{START}) + length(\$content)) >
    q($field->{LENGTH}) ?
      (q($field->{LENGTH}) - q($field->{START})) :
      length(\$content);
  substr(\$blank,$field->{START},\$replace_len,\$content);
  \$content = \$blank;
  }

if (ref(\$__etspec_destinations{q($outrecord->{DESTINATION})}->{handle}) eq 'ARRAY') {
  if (q($alias)) {
    push \@{\$outrecord},"$alias=\$content";
  } else {
    push \@{\$outrecord},"$values[0]=\$content";
  }
} else {
  \$outrecord = index_field
    (\$outrecord,
     qq(\$__etspec_destinations{q($outrecord->{DESTINATION})}->{field_delim}),
     $index,
     \$content);
}
ECODE
          } elsif (defined $field->{START}) {
            $internals_code .= <<ECODE;
my \$content;
if (q($field->{FORMAT})) {
  \$content = sprintf(q($field->{FORMAT}),$value);
} else {
  \$content = join('',$value);
}
my \$len = q($field->{LENGTH}) ne '' ?
q($field->{LENGTH}) :
q($field->{START}) + length(\$content);
my \$padc = q($field->{PADCHAR}) ? q($field->{PADCHAR}) : ' ';
my \$blank = \$outrecord;
my \$start;
if (q($field->{START}) < 0) {
  \$start = (q($field->{LENGTH}) + q($field->{START}));
} else {
  \$start = q($field->{START});
}
if (length(\$blank) < (q($field->{START}) + q($field->{LENGTH}))) {
  \$blank .=
  \$padc x ((q($field->{START}) + q($field->{LENGTH})) - length(\$blank));
}

my \$replace_len =
  (qq($field->{START}) + length(\$content)) >
  q($field->{LENGTH}) ?
    (q($field->{LENGTH}) - q($field->{START})) :
    length(\$content);
substr(\$blank,$field->{START},\$replace_len,\$content);

if (ref(\$__etspec_destinations{q($outrecord->{DESTINATION})}->{handle}) eq 'ARRAY') {
  if (q($alias)) {
    push \@{\$outrecord},"$alias=\$content";
  } else {
    push \@{\$outrecord},"$values[0]=\$content";
  }
} else {
  \$outrecord .= \$blank;
}
ECODE
          } else {
            $internals_code .= <<ECODE;
my \$content;

if (q($field->{FORMAT})) {
  \$content = sprintf(q($field->{FORMAT}),$value);
} else {
  \$content = join('',$value);
}


if (ref(\$__etspec_destinations{q($outrecord->{DESTINATION})}->{handle}) eq 'ARRAY') {
  if (q($alias)) {
    push \@{\$outrecord},"$alias=\$content";
  } else {
    push \@{\$outrecord},"$values[0]=\$content";
  }
} else {
  \$outrecord = index_field
    (\$outrecord,
     qq(\$__etspec_destinations{q($outrecord->{DESTINATION})}->{field_delim}),
     -1,
     \$content);
}
ECODE
          }
        }

        #Write the code to do the final rejection of
        #lines;
        $internals_code .= "my \$output_rejected = 0;";
        foreach my $reject_code (@{$outrecord->{REJECTS}}) {
          $reject_code = _field_interpolate({INFIELDS => $infields,
                             VALUE => $reject_code});
          $internals_code .= <<ECODE;
unless (defined \$__etspec_reject_code{q($reject_code)}) {
  \$__etspec_reject_code{q($reject_code)} = sub {
$reject_code
  };
}
my \$value = eval{\&{\$__etspec_reject_code{q($reject_code)}}()};
\$output_rejected++ if \$value;
ECODE
        }       

        $internals_code .= <<ECODE;
unless (\$output_rejected) {
no strict "refs";
if (ref(\$__etspec_destinations{q($outrecord->{DESTINATION})}->{handle}) eq 'ARRAY') {
  my \@values;
  my \$insert_sql;

  unless (qq($outrecord->{DESTINATION}) =~ /^proc:.*?(?::.*?)?\$/i) {
    my (\$table) = qq($outrecord->{DESTINATION}) =~ /^(.*?)(?::.*?)?\$/;
   \$insert_sql = join('',
                         "insert into \$table (",
                         join(',',
                              (map {
                                 my (\$key,\$value) = split(/=/,\$_,2);
                                 \$key;
                               } \@{\$outrecord})),
                         ") values (",
                         join(',',
                              (map {
                                 my (\$key,\$value) = split(/=/,\$_,2);
                                 (substr(\$value,0,5) eq 'FUNC:') ?
                                  substr(\$value,5) :
                                  eval {push \@values,\$value;"?"};
                               } \@{\$outrecord})),
                         ")");
  } else {
    my \$plsql;
    if (q($outrecord->{DESTINATION}) =~ /^proc:.*?:.*?\$/) {
      \$plsql = substr(q($outrecord->{DESTINATION}),
                       5,
                       (index(q($outrecord->{DESTINATION}),':',5) - 5));
    } else {
      \$plsql = substr(q($outrecord->{DESTINATION}),5);
    }

    \$insert_sql = join('',
                           "BEGIN\\n",
                           \$plsql,
                           '(',
                           join(',',(map {
                                          my (\$key,\$value) = split(/=/,\$_,2);
                                          (substr(\$value,0,5) eq 'FUNC:') ?
                                            substr(\$value,5) :
                                            eval {push \@values,\$value;"?"}
                              } \@{\$outrecord})),
                            ");\\nEND;\\n");
  }

  eval {
    my \$sth = \$__etspec_destinations{q($outrecord->{DESTINATION})}->{handle}->[0]
       ->prepare(\$insert_sql);
    my \$rv = \$sth->execute(\@values);
  };
  print STDERR "DBError: \$@\n" if \$@;

  if (++\$__etspec_destinations{q($outrecord->{DESTINATION})}->{handle}->[2] >
      \$__etspec_destinations{q($outrecord->{DESTINATION})}->{handle}->[1] and
      \$__etspec_destinations{q($outrecord->{DESTINATION})}->{handle}->[1] > 0) {
      \$__etspec_destinations{q($outrecord->{DESTINATION})}->{handle}->[2] = 0;
      \$__etspec_destinations{q($outrecord->{DESTINATION})}->{handle}->[0]->commit();
  }
} elsif (ref(\$__etspec_destinations{q($outrecord->{DESTINATION})}->{handle}) =~ /HTTP/) {
  #do http call with outrecord as content
  \$__etspec_destinations{q($outrecord->{DESTINATION})}->{handle}->content(\$outrecord);
  my \$response = \$__etspec_ua->request
    (\$__etspec_destinations{q($outrecord->{DESTINATION})}->{handle}->content(\$outrecord));

  unless (\$response->is_success) {
    throw Enigo::Common::Exception::General
      ({TYPE => 'UARequestFailed',
        TEXT => "User Agent Request for destination \$outrecord->{DESTINATION} failed."});
  }
} else {
use strict "refs";
  my \$outsep = qq(\$__etspec_destinations{q($outrecord->{DESTINATION})}->{record_delim});
  my \$handle = \$__etspec_destinations{q($outrecord->{DESTINATION})}->{handle};

  if (ref(\$handle) =~ /^IO::Scalar/) {
  \$handle->print("\$outrecord\$outsep");
  } else {
    print \$handle "\$outrecord\$outsep";
  }
}
}
ECODE
          }#close outrecord processing
        }
        my $subst = join('',
                     '<__',
                 $source,
                 '__internals>');
        $newcode =~ s/$subst/$internals_code/;
          }
    }
        $newcode .= <<ECODE;
sub die_handler {
  foreach my \$dest (keys \%__etspec_destinations) {
   next unless ((ref(\$__etspec_destinations{\$dest}->{handle}) eq 'ARRAY') and
                (\$__etspec_destinations{\$dest}->{handle}->[3]));
    \$__etspec_destinations{\$dest}->{handle}->[0]->disconnect();
  }
}

  foreach my \$dest (keys \%__etspec_destinations) {
   next unless ((ref(\$__etspec_destinations{\$dest}->{handle}) eq 'ARRAY') and
                (\$__etspec_destinations{\$dest}->{handle}->[1]));
    \$__etspec_destinations{\$dest}->{handle}->[0]->commit();
  }

die_handler();
ECODE
    $code =~ s|<!--__etspec_replace_$etspec_count-->|$newcode|gis;
        $etspec_count++;
    $newcode = undef;
      }
    }
  }
#  open FOO,">compiled_$$";print FOO $code;close FOO;
  return $code;
}

sub _field_interpolate {
  my ($param) = paramCheck([INFIELDS => 'AR',
                VALUE => 'U'],@_);
  my $value = $param->{VALUE};
  pos($param->{VALUE}) = 0;
  while ($param->{VALUE} =~ /\G.*?\[!--infield\s+([^-]+)--\]/sig) {
    my $field = $1;
    $value =~ s/\[!--infield\s+$field--\]/\$__etspec_infields->{$field}->{value}/;
  }

  $value =~
    s/\[!--allfields--\]/join('|',
                              map {$_->{value}}
                                \@{\$__etspec_infields}[1..$#{\$__etspec_infields}])/gex;

  return $value;
}

1;
