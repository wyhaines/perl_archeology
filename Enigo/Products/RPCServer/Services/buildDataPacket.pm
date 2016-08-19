#!perl
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: buildFileDataPacket.pm

Z<>

I<REVISION: $Revision: 1.1.1.1 $>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: $Date: 2001/12/17 02:28:37 $>

=head1 PURPOSE:

Builds a data packet of file information to return to Quetl.

=head1 EXAMPLE:

=head1 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

use strict;
use Enigo::Common::Sorts qw();
use Digest::MD5;

sub buildFileDataPacket {
  my ($param) = paramCheck([MAXLEN => ['N','4900000'],
                FILES => 'HR'],@_);

  #####
  #// Take the hash of hashrefs and return a sorted list of
  #// hash keys, where the sorting is based on the MTIME
  #// in each of the hashrefs.
  #####
  my @sorted_list =
    Enigo::Common::Sorts::sortHashByHRStringValue
    ($param->{FILES},'MTIME');

  my $packet;

  foreach my $file (@sorted_list) {
    #####
    #// Get the retry count;
    #####

    my $retry_count = get_retry_count($file);

    #Is it > 0?
    if ($retry_count > 0) {
      #If it is, is there anything in the data packet?
      if ($packet) {
    #If yes, return the data packet.
    return $packet;
      } else {
    #else add the current file to the packet, then return.
    add_file_to_packet({PACKET => $packet,
                MAXLEN => $param->{MAXLEN},
                FILE => [$file,$param->{FILES}->{FILE}]});
      }
    } else {
      #else add it to the data packet;
      add_file_to_packet({PACKET => $packet,
              MAXLEN => $param->{MAXLEN},
              FILE => [$file,$param->{FILES}->{FILE}]});
    }

    #Check packet size.
    last if packetSize($packet) >= $param->{MAXLEN};
  }

  return $packet;


  sub get_retry_count {
    my $filename = shift;

    my $sql = $Enigo::Products::RPCServer::SQL;
    my $sql_statement = <<'ESQL';
select retrycount from seen
where path = ?
ESQL
    my $retry_count;
    eval {
      $retry_count = $sql->scalar($sql_statement,$filename);
    };

    return $retry_count;
  }


  sub add_file_to_packet {
    my ($param) = paramCheck([PACKET => 'U',
                  MAXLEN => 'U',
                  FILE => 'AR'],@_);

    my ($filename,$file_stats) = @($param->{FILE});

    my $tail_data = tailFile({PATH => $filename,
                  MAXLEN => $param->{MAXLEN}});

    #####
    #// A file's data in a packet is composed of 5 items.
    #// First is the data itself.
    #####
    my $data = join('',@{$tail_data->[0]});

    #####
    #// Next is a beginning of file flag.
    #####
    my $bof = $tail_data->[3];

    #####
    #// Following that is a MD5 digest of the packet data.
    #####
    my $md5 = Digest::MD5->new();
    $md5->add($data);
    my $md5_p = $md5->b64digest();

    #####
    #// Next is the end of file flag.
    #####
    my $eof = $tail_data->[2];

    #####
    #// And finally is an MD5 digest for the entire file in question.
    #####
    $md5 = Digest::MD5->new();
    $md5->addfile(IO::File->new($filename,'r'));
    my $md5_f = $md5->b64digest();

    #####
    #// Now put it all together into the packet.
    #####
    $param->{PACKET}->{$filename} =
      [$data,
       $bof,
       $md5_p,
       $eof,
       $md5_f];
  }
}
