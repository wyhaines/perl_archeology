#!/usr/local/bin/perl -w
#
#################
## Header
#################
=pod

=head1 FILE_NAME: lc_supportCode.pm

I< >

I<REVISION: 1>

I<AUTHOR: Bill Keydel>

I<DATE_MODIFIED: 04 Oct 2001>

I< >

=head1 PURPOSE:

=over 4
This package provides the standard processing steps in the 
lc_.xml files by doing the following:

=item 1

Method "processOneResult" This is the starting point and only method intended to be called from outside.  
It assesses whether file level validation is required and whether the file is ready for linking 
or is still in the assemble phase. 

=item 2

Method "writePacket" handles the writing of the file and creating the symlink.

=item 3

Method "stdRPCRequest" sets max, earliest and unseen vars"

=back

=cut


package lc_supportCode;

use strict;
use Digest::MD5 qw(md5_base64);
use Enigo::Products::Quetl::Loggers::mkdirs; 
do "Enigo/Products/Quetl/Loggers/logTransaction.pm";
use Enigo::Products::Quetl::Loggers::logFileManip;
use Enigo::Products::Quetl::Loggers::lc_splitFiles; 


# processOneResult
#
# This is the primary method and only method to be called by the lc_.xml scripts
# It writes the file data received, validates the receipt at the file level,
# splits the file if appropriate and validates the split, and when all has
# all successfully makes the links to unprocessed.
# Expecting resultsARef to contain:
#            $resultsARef->[0]   to be the file data
#            $resultsARef->[1]   to be an bof flag
#            $resultsARef->[2]   to be a  md5 hash value of packet data transmitted
#            $resultsARef->[3]   to be an eof flag
#            $resultsARef->[4]   to be a  md5 hash value of the file being transmitted
#######################################################################################
sub processOneResult
{
#####  my ($param) = paramCheck([ origin =>
  my $child       = shift @_;
  my $task        = shift @_;
  my $server      = shift @_;
  my $origin      = shift @_;
  my $destination = shift @_;
  my $getsSplit   = shift @_;
  my $symPath     = shift @_;
  my $resultsARef = shift @_;
  my $tolerance   = shift @_;
  my $msgPrefix   = "lc_supportCode->processOneResult";

  my $msg = "$msgPrefix: Args received:  \n".
            "\t TASK:        $task, \n".
            "\t SERVER:      $server, \n".
            "\t ORIGIN:      $origin, \n".
            "\t DESTINATION: $destination, \n".
            "\t getsSplit:   $getsSplit, \n".
            "\t SYMPATH:     $symPath, \n".
            "\t RESULTSAREF: $resultsARef \n";   
            "\t TOLERANCE:   $tolerance \n";
  $Enigo::Products::Quetl::Dispatcher->log(level   => 'debug',
                                           message => "$msg");


  # Always write the file first, then test if needed.
  ####################################################
  writePacket($task, $origin, $destination, $resultsARef); 

  # eof signals need for file level validation.
  #############################################
  if ( ! $resultsARef->[3] )  
  {
    $Enigo::Products::Quetl::Dispatcher->log(level   => 'debug',
            message => "$msgPrefix: Incomplete file segment received. \n\n");
  } else
  {
    my $success = 0;


    # Tradeoff for reliability vs performance
    # File level validation is not needed when whole file transmitted
    # in one unit because it was accomplished by packet level validation.
    # However, if there was a problem writing the file preforming the
    # validation again would catch it.  So, I've been asked to comment
    # out the preformance savings till we've experience with the reliability.
    #########################################################################
    ##    if( $resultsARef->[1] && $getsSplit )
    ##    {
    ##      $Enigo::Products::Quetl::Dispatcher->log(level   => 'debug',
    ##              message => "$msgPrefix: Whole file received from $task,".
    ##                         " proceeding to splitFile. \n");
    ##      $success = splitFile($task, $tolerance, $destination);
    ##    } elsif( $resultsARef->[1] )
    ##    {
    ##      $Enigo::Products::Quetl::Dispatcher->log(level   => 'debug',
    ##              message => "$msgPrefix: Whole file received from $task,".
    ##                         " proceeding to linkFile. \n");
    ##      linkFile($task, $destination, $symPath); 
    ##      $success = 1;
    ##    } else
    ##    {

      my $failedToOpenFile = 0;
      my $RPC_hashValue = $resultsARef->[4];
      open WHOLEFILE, "<$destination" 
      or $failedToOpenFile = failToOpenFILE($destination);
      if ($failedToOpenFile){ goto RESPONSE; }
      my $md5 = Digest::MD5->new;
      $md5->addfile(*WHOLEFILE);
      my $md5_hashValue = $md5->b64digest();
      close WHOLEFILE;
      $Enigo::Products::Quetl::Dispatcher->log(level   => 'debug',
              message => "$msgPrefix: file testing on: $origin \n".
              "\t MD5 calculated: $md5_hashValue \n".
              "\t MD5 received:   $RPC_hashValue \n");

      # All files which did NOT transfer accurately are handled
      # the same at RESPONSE, when successful they are either split or linked.
      ####################################################################### 
      if ( $RPC_hashValue ne $md5_hashValue )
      {
        $success = 0;
      } else
      {
        $success = 1;
        if ( $getsSplit )
        {
          $Enigo::Products::Quetl::Dispatcher->log(level   => 'debug',
                  message => "$msgPrefix: $task file level validation passed,".
                             " proceeding to split the file. \n");
          splitFile($task, $tolerance, $destination); 
        } else
        {
          $Enigo::Products::Quetl::Dispatcher->log(level   => 'debug',
                  message => "$msgPrefix: $task file level validation passed,".
                            " proceeding to linkFile. \n");
          linkFile($task, $destination, $symPath); 
        } 
      }
    ##    }  # ends if bof is true which could bypass file validation

    # Set response to RPCServer based on result of File Validation
    # and if it failed validation test, delete the file.
    ###############################################################
    RESPONSE: my @args;
    if ( $success )
    {
      @args = ($task . "_fSuccess", $origin);
      logTransaction({TASK => $task,
                      ORIGINAL_PATH => $origin,
                      BYTES => length($resultsARef->[0]),
                      BOF => $resultsARef->[1],
                      EOF => $resultsARef->[3],
                      MD5_VALUE => $resultsARef->[4],
                      NEW_PATH => $destination,
                      VALIDATION => "passed_file",
                      DATE => time()            });
    } else
    {
      $Enigo::Products::Quetl::Dispatcher->log(level   => 'info',
              message => "$msgPrefix: File level validation failed; ".
                         "signaling RPCServer and deleting file.\n");
      @args = ($task . "_fFailure", $origin);
      logTransaction({TASK => $task,
                      ORIGINAL_PATH => $origin,
                      BYTES => length($resultsARef->[0]),
                      BOF => $resultsARef->[1],
                      EOF => $resultsARef->[3],
                      MD5_VALUE => $resultsARef->[4],
                      NEW_PATH => $destination,
                      VALIDATION => "failed_file",
                      DATE => time()            });
      my $numDeleted = unlink ($destination);
      if ( $numDeleted != 1 )      
      {
        $Enigo::Products::Quetl::Dispatcher->log(level   => 'major',
                message => "WARNING, $msgPrefix: Deleted: $numDeleted files".
                           " executing unlink $destination\n\n");
      }
    }

    $Enigo::Products::Quetl::Dispatcher->log(level   => 'debug',
            message => "$msgPrefix: Setup for RPCServer call: \n".
                       "\t Server: $server \n".
                       "\t Contents: @{[%$server]} \n".
                       "\t Params: @args \n");
    my @rpcResponse;
    eval 
    {
      push @rpcResponse,  $child->_make_RPC_call($server, \@args);
    };

    $Enigo::Products::Quetl::Dispatcher->log(level   => 'debug',
            message => "$msgPrefix: RESPONSE from RPC call: @rpcResponse\n");
    $Enigo::Products::Quetl::Dispatcher->log(level   => 'debug',
            message => "$msgPrefix: ERROR from RPC call: $@\n") if $@;

  }  # end if eof flag signaling need for file level validation
}

# linkFile
#
# This method is only used for log types where splitting does NOT occure.
##########################################################################
sub linkFile
{
  my $task = shift @_;
  my $fileToLink = shift @_;
  my $symPath = shift @_;
  my $msgPrefix = "lc_supportCode->linkFile";
  if( $fileToLink =~ m/nonCon/ )
  {
    $Enigo::Products::Quetl::Dispatcher->log(level   => 'major',
            message => "WARNING: $msgPrefix: nonCon file encountered: $fileToLink.\n");
  } else
  {
    mkdirs({PATH => $symPath});
    symlink $fileToLink, $symPath;
    $Enigo::Products::Quetl::Dispatcher->log(level   => 'info',
            message => "$msgPrefix: Linked: $fileToLink.\n".
            "                           To: $symPath \n" );
   logFileManip({TASK => $task,
                 SOURCE_PATH_FILE => $fileToLink,
                 ACTION => "link made",
                 NEW_PATH_FILE => $symPath,
                 DATE => time()              });

    $Enigo::Products::Quetl::Dispatcher->log(level   => 'debug',
            message => "$msgPrefix: Link made, Transaction logged.\n");
  }
}
# splitFile
################################################
sub splitFile
{
  my $task             = shift @_;
  my $tolerance        = shift @_;
  my $destination      = shift @_;
  my $msgPrefix        = "lc_supportCode->splitFile";
  my $failedToOpenFile = 0;
  my @data;

  open  ONEFILE, "<$destination"
                 or $failedToOpenFile = failToOpenFILE($destination);
  if ($failedToOpenFile)
  { 
    $Enigo::Products::Quetl::Dispatcher->log(level   => 'debug',
            message => "$msgPrefix: could NOT split file: $destination \n");
  } else
  {
    my $bsSize = (stat(ONEFILE))[7];
    while ( defined( my $line = <ONEFILE> ) )
    {
      chomp($line);
      push @data, $line;
    }
    close ONEFILE;
    my $dataARef = \@data;
    lc_splitFiles::selectSplitCode($task, $tolerance, $destination, $bsSize, $dataARef);
  }
}

# writePacket
#
# All log types will originally be writen to a single distination and THEN
# split if needed.  This routine handles the process of writing that first file.
#################################################################################
sub writePacket
{
  my $task = shift @_;
  my $origin = shift @_;
  my $destination = shift @_;
  my $resultsARef = shift @_;
  my $msgPrefix   = "lc_supportCode->writePacket";
  my $prefixSpace = "                          ";

  mkdirs({PATH => $destination});

  $Enigo::Products::Quetl::Dispatcher->log(level   => 'debug',
          message => "$msgPrefix: File: $origin \n".
                     "$prefixSpace Destination: $destination \n");
  open  LOGFILE, ">>$destination";
  print LOGFILE  $resultsARef->[0];
  close LOGFILE;

  logTransaction({TASK => $task,
                  ORIGINAL_PATH => $origin,
                  BYTES => length($resultsARef->[0]),
                  BOF => $resultsARef->[1],
                  EOF => $resultsARef->[3],
                  MD5_VALUE => $resultsARef->[2],
                  NEW_PATH => $destination,
                  VALIDATION => "passed_packet",
                  DATE => time()            });

  $Enigo::Products::Quetl::Dispatcher->log(level   => 'debug',
          message => "$msgPrefix: Write completed, Transaction logged.\n");

}
# failToOpenFILE
#
# Should a problem happen opening a file for file validation, we do NOT
# want the program to shut down, insteat log a critical alert.
#############################################################################
sub failToOpenFILE
{
  my $file = shift @_;
  my $msgPrefix = "lc_supportCode->failToOpenFILE";
  $Enigo::Products::Quetl::Dispatcher->log(level   => 'critical',
                            message => "$msgPrefix: Couldn't open $file\n"); 
  return 1;
}


return 1;
END { }
