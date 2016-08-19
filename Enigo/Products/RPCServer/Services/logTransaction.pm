#!perl
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: logTransaction.pm

=head1

I<REVISION: 1>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: 01 Feb 2001>

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

sub logTransaction {
  my ($param) = paramCheck([SERVICE => 'U',
                            BYTES => 'N',
                            PATH => 'U',
                POS => 'IO',
                DATE => 'IO'],@_);


  my $sql = $Enigo::Products::RPCServer::SQL;

  $param->{DATE} = time() unless defined $param->{DATE};

  my ($size,$atime,$mtime,$ctime) = (stat($param->{PATH}))[7..10];

  $param->{POS} = $size unless defined $param->{POS};

  $sql->insert
    (join('',
             'insert into history (service,date,path,bytes,lspos,size) values (',
             "'$param->{SERVICE}',",
             "'$param->{DATE}',",
             "'$param->{PATH}',",
             "'$param->{BYTES}',",
             "'$param->{POS}',",
             "'$size')"));

  return undef;
}


1;
