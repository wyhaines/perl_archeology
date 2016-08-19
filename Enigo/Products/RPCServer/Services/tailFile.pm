#!perl
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: tailFile.pm

=head1

I<REVISION: $Revision: 1.1.1.1 $>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: $Date: 2001/12/17 02:28:37 $>

=head1 PURPOSE:

Tails a file to return all of the lines that have been appended to the
file since the last time it was viewed.

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

sub tailFile {
  #####
  #// Declare a "constant", buffsize, to be our read buffer size.
  #####
  sub buffsize {40};

  my ($param) = paramCheck([PATH => 'U',
                MAXLEN => ['I',100000]],@_);

  my @stat_results = statFile({PATH => $param->{PATH}});
  my ($lsdate,$lspos,$flength,$hash) = @{$stat_results[0]}[0,1,4,5];
  my ($size,$atime,$mtime,$ctime) = @{$stat_results[1]};
  my $newfile = 0;

  #####
  #// If the lspos is greater than the file size, then the file
  #// has shrunk since we saw it last.  This must mean that the
  #// file is actually new.
  #####
  if ($lspos > $size and
      $lspos != 0) {
    resetSeen({PATH => $param->{PATH}});
    $lspos = 0;
    $newfile = 1;
  } elsif ($lspos == 0) {
    $newfile = 1;
  }

  #####
  #// The file will be read in 40 byte chunks.  We accumulate the
  #// data from these chunks into a scalar.  As soon as we find a
  #// newline in the data, we have a full line, so we will push
  #// that line to our array of lines, and then we update our
  #// last seen position to the last character in that line,
  #// seek to that position, and start fetching the next line.
  #// This keeps us from fetching partial lines as we will only
  #// push complete lines into the buffer.  Of course, this also
  #// means that a line will NOT be read if it is not terminated
  #// by a newline, even if it is the last line in the file.
  #####
  my $linebuffer;
  my $readbuffer;
  my @lines;
  my $date = time();
  $lspos = 0 unless ($lspos);
  my $file_len = $lspos;
  open TAILIT,"<$param->{PATH}";
  seek TAILIT,$lspos,0);
  while (read TAILIT,$readbuffer,buffsize()) {
    if (index($readbuffer,"\n") >= 0) {
      my ($first,$second) = split(/\n/,$readbuffer,2);
      $linebuffer .= "$first\n";
      $file_len += length($first);
      push @lines,$linebuffer;
      seek TAILIT,$file_len,0;
      $linebuffer = undef;
    } else {
      $linebuffer .= $readbuffer;
    }
    if (($file_len + length($linebuffer)) > ($lspos + $param->{MAXLEN})) {
      $linebuffer = undef;
      last;
    }
  }
  close TAILIT;

  seenFile({PATH => $param->{PATH},
        DATE => $date,
        POS => $file_len});

  return wantarray ? @lines : [\@lines,
                   $file_len,
                   ($file_len < $flength ? 0 : 1),
                   $newfile];
}
