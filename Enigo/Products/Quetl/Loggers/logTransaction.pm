#!perl
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: logTransaction.pm

=head1

I<REVISION: 2>

I<AUTHOR: Kirk Haines  revision: Bill Keydel>

I<DATE_MODIFIED: 02 Nov 2001>

=head1 PURPOSE:

Updates the transaction database with the record of a transaction.

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

sub logTransaction {
  my ($param) = paramCheck([TASK => 'U',
                            ORIGINAL_PATH => 'U',
                            BYTES => 'N',
                            BOF => 'N',
                            EOF => 'N',
                            MD5_VALUE => 'U',
                            NEW_PATH => 'U',
                            VALIDATION => 'U',
                            DATE => 'IO'],@_);


  my $sql = $Enigo::Products::Quetl::SQL;

  $param->{DATE} = time() unless defined $param->{DATE};
  my $size = "size 10";

  $sql->insert
    (join('',
             'insert into transactions (task,date,original_path,bytes,bof,eof,md5_value,new_path,validation) values (',
             "'$param->{TASK}',",
             "'$param->{DATE}',",
             "'$param->{ORIGINAL_PATH}',",
             "'$param->{BYTES}',",
             "'$param->{BOF}',",
             "'$param->{EOF}',",
             "'$param->{MD5_VALUE}',",
             "'$param->{NEW_PATH}',",
             "'$param->{VALIDATION}')"));

  return undef;
}

1;

END { }
