#!/usr/local/bin/perl -w -I/opt/enigo/common/perl/
#
#  Usage: perl -I dir/path/to/MX_Validation.pm  test-MX_Validation.pl  -d -a -f -l -n -k -t -u -s
#
#  -d  0|1  optional             Activate Debug mode  
#           0 -> indicates the test will run with OUT printing debug feedback
#           1 -> turns on debug mode in MX-Validation.pm causing it to print
#                a lot of lines about its status to the screen.
#           if omited, the default is: 1;
#
#  -a  0|1  optional             Array Mode Flag
#           0 -> indicates the test will pass domains individually 
#           1 -> indicates the test will pass the domains as an array
#           if omited, the default is: 1
#
#  -f  fileName optional         To specify a file with domain names to test
#           Pass in a file of domain names to be checked
#           if omited, the script will use one of two  internal arrays
#           determined by -l
#
#  -l  0|1  optional            To specify which internal array to use
#           0->  indicates to use the short list or 6 domain names
#           1->  indicates to use the long list of  20 domain names
#
#  -n  0|1  optional            To generate a list of NEW Error Responses
#           0 -> indicates the program is NOT to generate this Hash List
#           1 -> indicates a list of  domainName -> newErrorMessage is to be created
#                This will only list new error responses received from the MX lookup.
#           if omited, the default is: 0
#
#  -k  fileName optional        To specify a file of Common Domains
#           Pass in a file of: domainName|status  (freak.net|1) one per line
#           This file should only be a couple of hundred entries and represents
#           the domains which will be checked zero or one times when encountered
#           in the list to be checked.
#
#  -t  0|1  optional            To test or bypass testing the status of common domains
#           0 => indicates the program is NOT to test the status of common domains
#                and is to use the status in the file as loaded.
#           1 => indicates the program is to check the status of the common domains
#                the first time that domain encountered in the list being checked.
#           if omited, the default is: 0
#     Note: This impacts how MX_Validation.pm operates it does NOT update the source
#           file.  That is the responsiblity of the calling program, hence option -u 
#
#  -u  0|1  optional            To Update statuses in the knownDomain file 
#           0 -> indicates the is NOT to be updated
#           1 -> indicates the knownDomain file is to be updated
#           if omited, the default is: 0
#
#  -s  serverIP  optional       To specify the name server which is queried 
#           enter an IP address like:  "192.168.1.1" 
#           if omited the default name server is used (by passing default to checkMX() )

use strict;
use Getopt::Std;
use MX_Validation;

# Declare GLOBAL VARIABLES
##########################
my $DEBUG_FLAG   = 1;
my $ARRAY_FLAG   = 1;
my $TEST_FILE    = "";
my $NE_FLAG      = 0;
my $KD_FILE      = "";
my $USEKD_FLAG   = 0;
my $BYPASS_FLAG  = 0;
my $UPDATE_FLAG  = 0;
my $SL_FLAG      = 0;
my $SERVER       = "default";

main();
##############################################################################
sub main {

    getArguements();
    runIt();

}
##############################################################################
sub getArguements {

#   my ($opt_d, $opt_a, $opt_f, $opt_n, $opt_k, $opt_t, $opt_u, $opt_l, $opt_s);

	my %opts;

   getopts('d:a:f:n:k:t:u:l:s:', \%opts);

   if( defined $opts{d} ){ $DEBUG_FLAG = $opts{d}; }

   if( defined $opts{a} ){ $ARRAY_FLAG = $opts{a}; }

   if( defined $opts{f} ){ $TEST_FILE = $opts{f}; }

   if( defined $opts{n} ){ $NE_FLAG = $opts{n}; }

   if( defined $opts{k} ){ 
       $KD_FILE = $opts{k};
       $USEKD_FLAG = 1;
   }

   if( defined $opts{t} ){ $BYPASS_FLAG = $opts{t}; }

   if( defined $opts{u} ){ $UPDATE_FLAG = $opts{u}; }

   if( defined $opts{l} ){ $SL_FLAG = $opts{l}; }

   if( defined $opts{s} ){ $SERVER = $opts{s}; }
}
#############################################################################
sub runIt{
    
my(@test, $checker, $domain, $status, $line);

print "TEST SCRIPT:  Running as test-MX_Validation.pl\n";

   if( $TEST_FILE eq ""){ 
       if(defined $SL_FLAG){
          @test=("freak.net", "1N4WEB.COM", "1CPB.COM", "0ptonline.net", "10000RV.COM", "1C1.NET", "10BASEJ.COM", "123INDIA.COM", "1ACC.COM", "170KR.NET", "01019freenet.de", "1N4WEB.COM", "1CPB.COM", "0ptonline.net", "10000RV.COM", "1C1.NET", "10BASEJ.COM", "123INDIA.COM", "1ACC.COM", "clean.NET", "freak.net");
       }else{
          @test=("freak.net", "1N4WEB.COM", "1CPB.COM", "clean.NET", "freak.net", "1CPB.COM");
       }
   }else{
      open TFILE, "<$TEST_FILE"
                  or die "Cannot open $TEST_FILE\n";
      while (defined( $line = <TFILE> ) ){
         chomp($line);
         push(@test, $line);
      }
      close TFILE;
   }


   print "TEST SCRIPT:  Sending $#test items to MX_Validation.\n\n";

   if($USEKD_FLAG){
      open DLIST, "<$KD_FILE"
               or die "Cannot open $KD_FILE\n";
      my $FileHandle = \*DLIST;
      print "TEST SCRIPT:  FileHandle = $FileHandle\n";
      $checker = MX_Validation->new($UPDATE_FLAG, $NE_FLAG, $FileHandle);
   }else{
      $checker = MX_Validation->new($UPDATE_FLAG, $NE_FLAG);
   }

   my $results = $checker->checkMX($SERVER, @test);
   print "TEST SCRIPT:  The results are:\n";
   while(($domain, $status)=each(%$results)){
      print "\t\t\t\t$domain ==> $status\n";
   }
   close DLIST;

   if($NE_FLAG){
      my $newErrorsHashRef = $checker->get_NewErrors();
      print "now returning new errors;  Hash Ref is: $newErrorsHashRef\n";
      while(($domain, $status)=each(%$newErrorsHashRef)){
         print "\t\t\t\t$domain ==> $status\n";
      }
   }

   if($UPDATE_FLAG){
      my $updatedKDomainsRef = $checker->_getKDHashRef();
      open NLIST, ">$KD_FILE"
               or die "Cannot open $KD_FILE\n";
      print "Now writing to $KD_FILE the following:\n";
      while(($domain, $status)=each(%$updatedKDomainsRef)){
         print NLIST "$domain|$status\n";
         print "\t\t\t\t$domain ==> $status\n";
      }
      close NLIST;
   }

   print "TEST SCRIPT:  All done. \n";
}

