#!perl
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: seenFile.pm

=head1

I<REVISION: 1>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: 01 Feb 2001>

=head1 PURPOSE:

Updates the seen database for a list of files.

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

sub seenFile {
  my ($param) = paramCheck([PATH => 'U',
                POS => 'IO',
                DATE => 'IO',
                RETRY => ['U',0]],@_);


  my $sql = $Enigo::Products::RPCServer::SQL;

  $param->{DATE} = time() unless defined $param->{DATE};

  my ($size,$atime,$mtime,$ctime) = (stat($param->{PATH}))[7..10];

  $param->{POS} = $size unless defined $param->{POS};

  my $hash;
  {
    my $md5 = Digest::MD5->new;
    open(HASHIT,"<$param->{PATH}");
    $md5->addfile(*HASHIT);
    $hash = $md5->b64digest();
    close HASHIT;
  }

  my ($lsdate) =
      $sql->row(<<ESQL);
select trandate from seen where
path = '$param->{PATH}'
ESQL

  if ($lsdate) {
    $sql->update(<<ESQL);
update seen set trandate='$param->{DATE}',
                tranpos='$param->{POS}',
                length='$size',
                hash='$hash'
                where path='$param->{PATH}'
ESQL
  } else {
    $sql->insert(join('',
              'insert into seen (path,lsdate,lspos,length,hash) values (',
              "'$param->{PATH}',",
              "'$param->{DATE}',",
              "'$param->{POS}',",
              "'$size',",
              "'$hash')"));
  }
  return undef;
}


1;
