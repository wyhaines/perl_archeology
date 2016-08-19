#!/usr/local/bin/perl -w

# Documentation
###############
=pod

=head1 FILE_NAME:  lc_splitFiles.pm

I< >

I<REVISION: 1 >

I<AUTHOR:  Bill Keydel>

I<DATE_MODIFIED: 08 Oct 2001>

I< >

=head1 PURPOSE:

=over 4
This package serves to seperate the split file code used
by various lc_.xml types from the standard processes.  
Any changes or additions to the log collection routines will
no longer impact lc_supportCode.pm.  And this file will only
require entry of the related package name.

=item 1

Method "selectSplitCode" simply selects the appropriate package
needed to split the file.

=back

=cut

# End Documentation

package lc_splitFiles;

use strict;
use Enigo::Products::Quetl::Loggers::lc_testSplit;

sub selectSplitCode
{
  my $task       = shift @_;
  my $tolerance  = shift @_;
  my $bsFileName = shift @_;         # bs stands for before split
  my $bsFileSize = shift @_;
  my $dataARef   = shift @_;
  my $scPackage  = "lc_split$task";  # This sets a standard requiring any package for 
                                     # splitting files be named "lc_split . task.pm"
  my $msgPrefix  = "lc_splitFiles->selectSplitCode";
  my ($bsPath)   = $bsFileName =~ /^(.*)\/collected/ ;  
  my $success    = 0;


  # Execute code for splitting of file
  ####################################
  my $package = "lc_split$task";
  my $logSizesHRef;
  $Enigo::Products::Quetl::Dispatcher->log(level   => 'debug',
          message => "$msgPrefix:   Evaluating:  ".
                     "${package}::doSplit($bsPath, $bsFileName, $dataARef )\n\n");
  my $code = "\$logSizesHRef = ${scPackage}::doSplit( \$bsPath, \$bsFileName, \$dataARef )";

  eval (join("\n",
         "use Enigo::Products::Quetl::Loggers::${scPackage};",
         $code));
  $Enigo::Products::Quetl::Dispatcher->log(level   => 'debug',
          message => "$msgPrefix: ERROR Evaluating: \n".
                     "${package}::doSplit($bsPath, $bsFileName, $dataARef )\n".
                     "$@\n\n") if $@;

  # Test completeness of split files
  ###################################
  $Enigo::Products::Quetl::Dispatcher->log(level   => 'debug',
          message => "$msgPrefix:  Executing lc_testSplit::testSplit(".
                     "bsFileName: $bsFileName, bsFileSize: $bsFileSize, ".
                     "logSizesHRef: $logSizesHRef, Tolerance: $tolerance)\n");
  $success = lc_testSplit::testSplit($bsFileName, $bsFileSize, $logSizesHRef, $tolerance);
  
  # Make links
  #############
  if ( $success )
  {
    $Enigo::Products::Quetl::Dispatcher->log(level   => 'debug',
            message => "$msgPrefix:   Evaluating:  ".
                       "${package}::mkLinks($bsPath, $logSizesHRef)\n");
    my $code = "${scPackage}::makeLink(\$task, \$bsPath, \$logSizesHRef )";

    eval ($code);
    unlink($bsFileName);
  }
  return $success;
}
return 1;
END { }
