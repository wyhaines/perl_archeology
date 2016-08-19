#!/usr/local/bin/perl -w

# Documentation
###############
=pod

=head1 FILE_NAME: lc_splitMTA.pm

I< >

I<REVISION: 1>

I<AUTHOR:  Bill Keydel>

I<DATE_MODIFIED:  08 Oct 2001>

I< >

=head1 PURPOSE:

=over 4
This package provides the logic needed to split the netscape
smtp logs.

=item 1

Method "doSplit"  Splits files by date of records so that
all resulting files contain only records of the same date.

=back

=cut

# End Documentation

package lc_splitMTA;

use strict;
use IO::File;
use Enigo::Common::DtConvert;
use Enigo::Products::Quetl::Loggers::lc_supportCode;
do "Enigo/Products/Quetl/Loggers/mkdirs.pm";
do "Enigo/Products/Quetl/Loggers/logFileManip.pm";

# make a simlink to the unprocessed directory for all
# files that have been created (in the files hash)
######################################################
sub makeLink
{
  my $task =shift @_;
  my $base = shift @_;
  my $fileSizesHRef = shift @_;
  my $msgPrefix = "lc_splitMTA->makeLink";

  $Enigo::Products::Quetl::Dispatcher->log(level   => 'debug',
          message => "$msgPrefix: Received: task: $task,   base: $base \n".
          "\t fileSizesHRef:  @{[%$fileSizesHRef]} \n");

  foreach my $fullPath (keys %$fileSizesHRef){
    my  ($fileName) = $fullPath =~ /.*(smtp.*)$/ ;
    my ($mtaType) = $fileName =~ /.*_(fast|slow|offline|arch|sendmail)_.*$/ ;
    my $symPath = "$base/unprocessed/$mtaType/$fileName";
    lc_supportCode::linkFile($task,$fullPath,$symPath);
  }
}

# expecting file names like: "preSplit:lisa:sendmail:4321:1616.1002327632"
###########################################################################
sub doSplit
{
  my $base = shift @_;
  my $bsFile = shift @_;
  my $dataARef = shift @_;
  my %logfiles;
  my $msgPrefix = "lc_splitMTA->doSplit";

  my ($hostname, $mtaType, $ttl, $smtpNum) = $bsFile =~ 
      /^.*preSplit:(\w*):(\w*):(\w*):(\d+\.\d+)$/;
  my $filePrefix =  "smtp_$hostname" . "_$mtaType" . "_$ttl";

  $Enigo::Products::Quetl::Dispatcher->log(level   => 'debug',
          message => "$msgPrefix: \n".
          "\tReceived  -> base: $base, bsFile: $bsFile, dataARef: $dataARef\n". 
          "\tExtracted -> hostname: $hostname, mtaType: $mtaType, ttl: $ttl, ".
          "smtpNum: $smtpNum\n".
          "\tUsing     -> filePrefix: $filePrefix, smtpNum: $smtpNum\n");

  # Splitting the data so that records are in files according to
  # their date.  Make the record date available for use in the file name
  ######################################################################
  my ($day, $month, $year);
  my ($oldDay, $oldMon, $oldYear) = ("dd", "Mon", "yyyy");
  foreach my $line (@$dataARef){
    unless ( ($day,$month,$year) = $line =~ /^\[(\d\d)\/(\w{3})\/(\d{4})/ ){
        ($day, $month, $year) = ($oldDay, $oldMon, $oldYear);
    }
    my $fDate = "${day}${month}${year}";
    my $outFile = "${filePrefix}_${fDate}_${smtpNum}.log";
    my $dateStp = Enigo::Common::DtConvert::yyyymmdd($fDate);
    my $destination = "$base/collected/$dateStp/$mtaType/$outFile";

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
    ($oldDay, $oldMon, $oldYear)=($day, $month, $year) ;
  }

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
