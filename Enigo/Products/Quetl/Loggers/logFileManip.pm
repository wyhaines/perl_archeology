#!perl
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: logFileManip.pm

=head1

I<REVISION: 2>

I<AUTHOR: Bill Keydel>

I<DATE_MODIFIED: 05 Nov 2001>

=head1 PURPOSE:

Updates the filesManiped database with the record of a file split or link.

=head1 EXAMPLE:

=head1 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

use strict;
use Enigo::Common::ParamCheck qw(paramCheck);
use Digest::MD5 qw(md5_base64);
use Error qw(:try);

BEGIN
{
#  use Exporter();
#  @ISA = qw(Exporter);
#  @EXPORT = qw(&logTransaction);
}

sub logFileManip {
  my ($param) = paramCheck([TASK => 'U',
                            SOURCE_PATH_FILE => 'U',
                            ACTION => 'U',
                            NEW_PATH_FILE => 'U',
                            BYTES => 'NO',
                            DATE => 'IO'],@_);


  my $sql = $Enigo::Products::Quetl::SQL;

  $param->{DATE} = time() unless defined $param->{DATE};

  $param->{BYTES} = (stat($param->{NEW_PATH_FILE}))[7] unless defined $param->{BYTES};

  $sql->insert
    (join('',
             'insert into filesManiped (task,date,source_path_file,action,new_path_file,bytes) values (',
             "'$param->{TASK}',",
             "'$param->{DATE}',",
             "'$param->{SOURCE_PATH_FILE}',",
             "'$param->{ACTION}',",
             "'$param->{NEW_PATH_FILE}',",
             "'$param->{BYTES}')"));

  return undef;
}

1;

END { }
