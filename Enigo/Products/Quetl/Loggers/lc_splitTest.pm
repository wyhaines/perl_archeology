#!/usr/local/bin/perl -w

# Documentation
###############
=pod

=head1 FILE_NAME: lc_testSplit

I< >

I<REVISION: 1>

I<AUTHOR: Bill Keydel>

I<DATE_MODIFIED: 08 Oct 2001>

I< >

=head1 PURPOSE:

=over 4

  This package provides a standard method for testing the success
of file splitting by comparing the aggregated bytes of all resulting
files to the bytes of the source file.

=item 1

Method "testSplit" receives 

=item 1  

1. sourceSize, 

=item 2

2. a Hash of fileNames=>size (in bytes)

=item 3

3. a value for the tolerance in discrepancies

And returns success (1) or failure (0).

=cut

# End Documentation


package  lc_testSplit;

use strict;

sub testSplit
{
  my $bsFile = shift @_;
  my $sourceSize = shift @_;
  my $fileSizesHRef = shift @_;
  my $tolerance = shift @_;
  my $success = 0;
  my $aggerateSize = 0;
  my $numDeleted = 0;
  my $msgPrefix = "lc_splitTest->testSplit";

  $Enigo::Products::Quetl::Dispatcher->log(level   => 'debug',
          message => "$msgPrefix: bsSize: $sourceSize bsFile: $bsFile\n".
                     "Tolerance: $tolerance, fileSizesHRef: @{[%$fileSizesHRef]}\n");

  # To create automated testing
  # real SMTP logs donot start stmp.0
  # smtp.09993 logs will fail split test
  # smtp.09994 logs will pass bytesPerSplit
  # smtp.09995 logs will pass percentOfBytes
  ###########################################
  my $origSize;
  if ($bsFile =~ m/:0999[3-5]/ )
  {
    print STDERR "Forcing change in file size.\n";
    $origSize = $sourceSize; # Tool for testing
    $sourceSize = 100000; # Force error for testing
  }


  # Files have now been split and closed. Now Test.
  ################################################
  foreach my $size (values %$fileSizesHRef)
  {
    $aggerateSize += $size;
  }

  $Enigo::Products::Quetl::Dispatcher->log(level   => 'debug',
          message => "$msgPrefix: Tolerance is: $tolerance. \n");

  if ( $aggerateSize ==  $sourceSize )
  {
    $success = 1;
    $Enigo::Products::Quetl::Dispatcher->log(level   => 'info',
            message => "$msgPrefix: $bsFile tolerance check: aggSize == sourceSize  $sourceSize bytes. \n"); 
  } else
  {
    my @toleranceChecks = split /:/, $tolerance;

    # test file size against allowable discrepancies as indicated by tolerance checks
    # expecting tolerance to contain something like:  percentOfBytes=.0095:bytesPerSplit=10
    ##########################################################################################
    foreach my $tc (@toleranceChecks)
    {
      if ($bsFile =~ m/:0999[3-5]/){$sourceSize = 100000; }     # To create automated testing
      my $bytesOff;
      my ($method, $factor) = split /=/, $tc;
      if ($method =~ m/bytesPerSplit/     )
      { 
        if ($bsFile =~ m/:09994/){$sourceSize = $origSize; }    # To create automated testing
        $bytesOff =  scalar(@{[%$fileSizesHRef]}) * $factor / 2; 
      } elsif ($method =~ m/percentOfBytes/ )
      { 
        if ($bsFile =~ m/:09995/){$sourceSize = $origSize; }    # To create automated testing
        $bytesOff = $sourceSize * $factor; 
      } else 
      {  
        $Enigo::Products::Quetl::Dispatcher->log(level   => 'critical',
        message => "$msgPrefix: Unknown method of split evaluation encountered:  $method = $factor\n"); 
        next;
      }
      my $lowEnd = $sourceSize - $bytesOff;
      my $highEnd = $sourceSize + $bytesOff;
      $Enigo::Products::Quetl::Dispatcher->log(level   => 'debug',                                                                                        
                message => "$msgPrefix: $bsFile tolerance check: $method = $factor  ($lowEnd <= $aggerateSize <= $highEnd)\n");
      if ($lowEnd <= $aggerateSize && $aggerateSize <= $highEnd)
      {
        $success = 1;
        $Enigo::Products::Quetl::Dispatcher->log(level   => 'info',
                message => "$msgPrefix: $bsFile split within tolerance check: $method = $factor  ($lowEnd <= $aggerateSize <= $highEnd)\n");
      }
    }
  }

    
  if ( $success == 0 )
  {
    my $numSplitErrs = 0;
    
    # The files created by splitting should be moved from the directories
    # containing successfully collected files if split doesn't validate.
    ######################################################################
    foreach my $file (keys %$fileSizesHRef)
    {
      my ($errFileName) = $file ;
      $errFileName =~ s/collected\/\d+/collected\/badSplits/ ;
      do "Enigo/Products/Quetl/Loggers/mkdirs.pm";
      mkdirs({PATH => $errFileName});
      my $result = rename($file, $errFileName);
      $numSplitErrs += 1;
    }
    $Enigo::Products::Quetl::Dispatcher->log(level   => 'major',
            message => "WARNING: File split with ERRORS: $bsFile\n".
                       "$numSplitErrs files moved to collected/badSplits: \n@{[%$fileSizesHRef]} \n");
  }
  return $success;
}

return 1;
END { }

