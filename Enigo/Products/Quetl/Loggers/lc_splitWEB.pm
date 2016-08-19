#!/usr/local/bin/perl -w

# Documentation
###############
=pod

=head1 FILE_NAME: lc_splitWEB.pm

I< >

I<REVISION: 1>

I<AUTHOR:  Bill Keydel>

I<DATE_MODIFIED:  01 Nov 2001>

I< >

=head1 PURPOSE:

=over 4
This package provides the logic needed to split the web logs.

=item 1

Method "doSplit"  Splits files by date of records so that
all resulting files contain only records of the same date.

=back

=cut

# End Documentation

package lc_splitWEB;

use strict;
use IO::File;
use Enigo::Common::DtConvert;
use Enigo::Products::Quetl::Loggers::lc_supportCode;
do "Enigo/Products/Quetl/Loggers/mkdirs.pm";
do "Enigo/Products/Quetl/Loggers/logFileManip.pm";

# makeLink is a procedure required by lc_splitFiles.pm
# However, web log packets are linked so the split 
# logs do not get linked.  Hence, an empty routine.
######################################################
sub makeLink
{
  my $task =shift @_;
  my $base = shift @_;
  my $fileSizesHRef = shift @_;
}

# expecting file names like: "preSplit:web01access
###########################################################################
sub doSplit
{
  my $base = shift @_;
  my $bsFile = shift @_;
  my $dataARef = shift @_;
  my %logfiles;
  my $msgPrefix = "lc_splitWEB->doSplit";

  $Enigo::Products::Quetl::Dispatcher->log(level   => 'debug',
          message => "$msgPrefix: BASE: $base, FILE: $bsFile, DATA: $dataARef, \n");
  $bsFile =~ s/^.*preSplit://;

  # Splitting the data so that records are in files according to
  # their date.  Make the record date available for use in the file name
  ######################################################################
  my ($dd, $Mon, $yyyy);
  my ($oldDay, $oldMon, $oldYear) = ("dd", "Mon", "yyyy");
  foreach my $line (@$dataARef){
    unless (($dd,$Mon,$yyyy) = $line =~ /^.*\[(\d\d)\/(\w{3})\/(\d{4}):/) {
        ($dd, $Mon, $yyyy) = ($oldDay, $oldMon, $oldYear);
    }
    my $ddMonyyyy = $dd . $Mon . $yyyy; 
    my $yyyymmdd = Enigo::Common::DtConvert::yyyymmdd($ddMonyyyy);
    my $outFile = "${bsFile}_${ddMonyyyy}.log";
    my $destination = "$base/collected/$yyyymmdd/open/webAccess/$outFile";

    # if a new file is needed, open a file handle and list in the files hash
    ########################################################################
    unless($logfiles{$destination}){
      mkdirs({PATH => $destination});
      my $fh = IO::File->new(">> $destination");
      $logfiles{"$destination"} = $fh;
    }

    # write the line to the appropriate file
    ########################################
    my $fh = $logfiles{$destination};
    print $fh "$line\n";
    ($oldDay, $oldMon, $oldYear)=($dd, $Mon, $yyyy) ;
  } # end processing each line of data

  # get sizes of resulting files and close file handles
  ######################################################
  my %logSizes;
  foreach my $destFile (keys %logfiles)
  {
    my $fh = $logfiles{$destFile};
    $fh->close();
    my $size = (stat($destFile))[7];
    $logSizes{$destFile} = $size;
    logFileManip({TASK => $lc::task,                                                                                                                        
                    SOURCE_PATH_FILE => $bsFile,                                                                                                            
                    ACTION => "split file made",                                                                                                            
                    NEW_PATH_FILE => $destFile,                                                                                                             
                    BYTES => $size,                                                                                                                         
                    DATE => time()            });                                                                                                           
  }

  $Enigo::Products::Quetl::Dispatcher->log(level   => 'debug',                                                                                              
          message => "$msgPrefix: logSizes: @{[%logSizes]} \n\n");    

  my $logSizesHRef = \%logSizes;

  return $logSizesHRef;
}
return 1;
END { }
