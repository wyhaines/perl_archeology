#!perl
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: listFiles.pm

Z<>

I<REVISION: $Revision: 1.1.1.1 $>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: $Date: 2001/12/17 02:28:37 $>

=over 4

=item PURPOSE:

Returns a list of files meeting certain criteria.  These criteria
include the age of the files, the names/locations of the files,
and whether those files are listed as already seen in the seen
database.

=item ARGUMENTS:

=over 4

=item UNSEEN

=item TIME

=item PATH

=item MASK

=item RECURSIVE

=over 4

=item EXAMPLE:

  listFiles({PATH => '/var/log/hiper',
             MASK => '.*\.log'});


=item TODO:

=over 4

=item Follow symlinks flag

Add a flag to interactively set whether symlinks are followed or
not when generating the file list.

=back

=back

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

use strict;
use Enigo::Common::ParamCheck qw(paramCheck);
use File::Find;
use Digest::MD5 qw(md5_base64);
use Data::Dumper;

sub listFiles {
  use vars qw(%file_list $param $sql);

  local ($param) = paramCheck([UNSEEN => ['U',1],
                   TIME => ['I',-1],
                   PATH => 'U',
                   MASK => 'U',
                   RECURSIVE => ['U',1]],@_);

  local %file_list = ();

  local $sql = $Enigo::Products::RPCServer::SQL;

  unless (ref($param->{PATH}) eq 'ARRAY') {
    $param->{PATH} = [$param->{PATH}];
  }

  #####
  #// Find all of the files.
  #####
  find({wanted => \&wanted,
    follow => 1},@{$param->{PATH}});

  return \%file_list;

  sub wanted {
    my $filename = $_;
    my $dir = $File::Find::dir;
    my $filepath = $File::Find::name;

    unless ($param->{RECURSIVE}) {
      foreach my $path (@{$param->{PATH}}) {
    return undef if $filepath =~ m{$path/[^/]+/[^/]+};
    }
    }

    unless ($filepath =~ m{$param->{MASK}}) {
      return undef;
    }

    my @stat_results = statFile({PATH => $filepath});

    my ($lsdate,$lspos,$flength,$hash) = @{$stat_results[0]}[0,1,4,5];
    my ($size,$atime,$mtime,$ctime) = @{$stat_results[1]};

    #####
    #// This set of parameters means to select all of the filenames
    #// encountered, regardless of the last modification date or
    #// whether the file has been seen before.
    #####
    if (($param->{TIME} < 1) and
    !$param->{UNSEEN}) {
      $file_list{$filepath} = {LSDATE => $lsdate,
                   LSPOS => $lspos,
                   SIZE => $size,
                   MTIME => $mtime,
                   NEW => 1};
      return $filename;
    }

    #####
    #// If we match this set of parameters, then what is wanted is
    #// any file that has not been seen, or has changed since it
    #// was last seen, regardless of the last modification date.
    #####
    if (($param->{TIME} < 1) and
    $param->{UNSEEN}) {

      my $retval = {LSDATE => $lsdate,
            LSPOS => $lspos,
            SIZE => $size,
            MTIME => $mtime,
                    NEW => 1};
      ($file_list{$filepath} = $retval) && return $filename
    if (!$lsdate);

      $retval->{NEW => undef};

      if ($lspos != $size) {
    $file_list{$filepath} = $retval;
    return $filename;
      }

      if ($lsdate and ($mtime > $lsdate)) {
    my $digest;
    {
      my $md5 = Digest::MD5->new;
      open(DIGESTIT,"<$filepath");
      $md5->addfile(*DIGESTIT);
      $hash = $md5->b64digest();
      close DIGESTIT;
    }

    return undef unless ($digest ne $hash);

    $file_list{$filepath} = $retval;
    return $filename;
      }

      return undef;
    }

    #####
    #// Okay, it doesn't matter if we've seen it or not or whether it
    #// has changed or not; we want it if the last modified time is
    #// late enough.
    #####
    if (($param->{TIME} >= 1) and
    !$param->{UNSEEN}) {

      my ($size,$atime,$mtime,$ctime) = (stat($filepath))[7..10];

      ($file_list{$filepath} = {LSDATE => $lsdate,
                LSPOS => $lspos,
                SIZE => $size,
                MTIME => $mtime,
                NEW => 1}) &&
                  return $filename
                    if $mtime > $param->{TIME};

      return undef;
    }

    #####
    #// Here's the option that is actually the most common one to
    #// actually use.  Select only those files which have been
    #// modified later than the given time and that either we
    #// have not seen the file yet or it has changed since the
    #// last time that we saw it.
    #####
    if (($param->{TIME} >= 1) and
    $param->{UNSEEN}) {
      my ($size,$atime,$mtime,$ctime) = (stat($filepath))[7..10];

      #####
      #// It's new enough?
      #####
      return undef unless ($mtime > $param->{TIME});

      my $retval = {LSDATE => $lsdate,
            LSPOS => $lspos,
            SIZE => $size,
            MTIME => $mtime,
            NEW => 1};

      #####
      #// Have we seen it before?
      #####
      if (!$lsdate) {
        $file_list{$filepath} = $retval;
    return $filename;
      }

      $retval->{NEW => undef};

      if ($lspos != $size) {
    $file_list{$filepath} = $retval;
    return $filename;
      }

      #####
      #// Okay, we've seen it before, but perhaps it has changed.
      #####
      if ($lsdate and ($mtime > $lsdate)) {
    my $digest;
    {
      my $md5 = Digest::MD5->new;
      open(DIGESTIT,"<$filepath");
      $md5->addfile(*DIGESTIT);
      $hash = $md5->b64digest();
      close DIGESTIT;
    }

    return undef unless ($digest ne $hash);

    $file_list{$filepath} = $retval;
    return $filename;
      }

      return undef;
    }
  }
}


1;
