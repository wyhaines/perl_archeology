#!/usr/local/bin/perl -w

#  Primary Methods of the class
#
#      new()
#      checkMX()
#      lookUp()         (for add hoc use)
#      get_NewErrors()

package MX_Validation;

use Net::DNS;
use strict;


# Set values of class constants;  
############################################################################################
{
   my @_AVAILABLE    = (1, "UP");       # our assignment    - MX for domain name validated
   my @_NODOMAIN     = (2, "NXDOMAIN"); # DNS Response Code - Non-Existent Domain
   my @_SERVFAIL     = (3, "SFAIL"); # DNS Response Code - Server Failure
   my @_UNCLEAR      = (4, "NOERROR");  # DNS Response Code - No Error (but no MX returned)
   my @_UNCHECKED    = (5, "NT");       # our assignment    - Not Tested
   my @_NEWRESPONSE  = (6, "OT");       # Other Response    - Some other DNS response received.

   sub get_AVAILABLE    { @_AVAILABLE[$_[1]]    }
   sub get_NODOMAIN     { @_NODOMAIN[$_[1]]    }
   sub get_SERVFAIL     { @_SERVFAIL[$_[1]]    }
   sub get_UNCLEAR      { @_UNCLEAR[$_[1]]      }
   sub get_UNCHECKED    { @_UNCHECKED[$_[1]]    }
   sub get_NEWRESPONSE  { @_NEWRESPONSE[$_[1]]  }

}
# End of anonymous block


#  The constructor for this class
#  The user of this class is expected to pass in, IN ORDER,
#
#  1: the class reference  (typically automatic with use of arrow infix operator)
#
#  2: A flag 0|1 signaling if the known domains file should be checked.
#             0  indicates that the statuses in the file will be used w/o lookup.
#             1  indicates that a MX lookup should be perform the first time the
#                domain is queried.
#
#  3: A flag 0|1 signaling if a hash is to be collected for new error messages
#     returned from the internet to the lookup function.
#             0  indicates that the hash should NOT be created.
#             1  creates the hash of domains=>errorStrings  
#                where errorStrings are error messages
#                returned from the internet MX lookup which we aren't testing for.
#     That hash can then be returned by calling ->get_NewErrors
#
#  4: A Reference to the File Handle for the file of 100 or so common domains
################################################################################
sub new{

   my $self = shift @_;
   my $_update = shift @_;
   my $_collectNewErrors = shift @_;
   my ($kdFileHandle, $readFile); 

   if( ! exists  $_[0] || $_[0]==0 ){
      $readFile = 0;
   }else{
      $kdFileHandle = shift @_;
      $readFile = 1;
   }

   my %kdHash=();
   my $_kdHashRef = \%kdHash;
   my %newErrors=();
   my $_newErrorsHashRef =  \%newErrors;
   my $debug = 0;
   my $server = "default";
   my $objref = { debug => $debug,  NewErrorsFlag => $_collectNewErrors, server => $server, _kdHashRef => $_kdHashRef, _newErrorsHashRef => $_newErrorsHashRef };

   bless $objref, $self;
print "SUB NEW VALUES:  objref = $objref, file = $readFile,  update flag = $_update,  kdRef = $_kdHashRef,  kdFileHandle = $kdFileHandle\n" if $objref->getDEBUG;
   _loadKDomains($objref, $readFile, $_update, $_kdHashRef, $kdFileHandle);
   return $objref; 
}

sub _getKDHashRef     { $_[0]->{_kdHashRef}           }
sub get_NewErrors     { $_[0]->{_newErrorsHashRef}    }
sub getDEBUG          { $_[0]->{debug}                }
sub setDEBUG          { $_[0]->{debug} = $_[1]        }
sub getNewErrorsFlag  { $_[0]->{NewErrorsFlag}        }
sub setNewErrorsFlag  { $_[0]->{NewErrorsFlag} = $_[1]}
sub getServer         { $_[0]->{server}               }
sub setServer         { $_[0]->{server} = $_[1]        }


# sub setNameserver sets the nameserver that this object does DNS lookups at
#
# Params: a string containing the hostname or IP address of the nameserver
#
# Returns: nothing
################################################################################
sub setNameserver
{
    my $self = shift;
    my $nameserver = shift;

    my $res = new Net::DNS::Resolver;

    $res->nameservers($nameserver);

    $self->{resolver} = $res;
}


#  sub _loadDomainHash opens the file "domain-list.txt" and loads them into
#      the knownDomainHash as keys with all values set to UNCHECKED.
#
#  Params:  None  but the routine expects to find the file "domain-list.txt"
#           containing a list of domains, one per line.  The intent is that this
#           list will contain 100 or so of the most commonly used domains.
#  Returns: Hash Reference for hash containing domain => status of the 
#           100 or so most commonly used domains.
################################################################################
sub _loadKDomains{

   my $self = shift @_;
   my $readFile = shift @_;
   if (! $readFile){ return; }
   my $_update = shift@_;
   my $_kdHashRef = shift @_;
   my $kdFileHandle = shift @_;
   my($line); 
   my ($key, $value);
   print "SUB LOADKDOMAINS VALUES: Self=$self, Hash=$_kdHashRef, File Handle = $kdFileHandle\n" if $self->getDEBUG;
   while ( defined( $line = readline(*$kdFileHandle) )) {
      chomp($line);
      $line=~/^\s*(\S+)\s*$/;
      ($key, $value) = split /\|/, $line;
      if( $_update ){
         $_kdHashRef->{$key} = $value;
      }else{
         $_kdHashRef->{$key} = $self->get_UNCHECKED(0);
      }
   }
   print "SUB LOADKDOMAINS:  Known Domains loaded.  Ref is: $_kdHashRef  It contains:\n" if $self->getDEBUG;
   while( ($key, $value) = each(%$_kdHashRef)){
        print "SUB LOADKDOMAINS:\t\t$key => $value LOADED\n" if $self->getDEBUG;
   }
   print "\n" if $self->getDEBUG;
}




# sub checkMX is the routine other programs will call to perform a check of
#     viability of an domain name for receiving mail.  Essentially it checks
#     to see if a mail exchange exists for a given domain name and its status.
#     It takes 1 to many domain names and checks them in two ways:
#     1:   the domain is compared to the list of most common domains, 
#          if it matches, then it returns the status stored for that domain
#          without actually accessing the internet  (except the first time
#          the stored domain is matched, then it is checked and its status set)
#     2:   if the domain doesn't match one of the common domains,  the program
#          executes a MX lookup via sub lookUp.  
#
# Params:  1: reference to self as object
#          2: One or more domain names 
#             (one domain name as string; multiple as an array of names)     
#
# Returns: a status string if one domain was passed
#          a hash reference to a hash containing  domain => status elements
#
# Status Values returned:
#          UP = Indicates a mail exchange exists and is accessible.
#    NXDOMAIN = Indicates that there is no mail exchange for a domain name.
#    SERVFAIL = Indicates that there was some technical problem checking
#               for the mail exchange.  The exchange may exist, just be off line.
#    NOERROR  = Indicates that no mail exchange information was returned from
#               the query even though no error messages were encountered.
#               Also returned if an error message other than NXDOMAIN or
#               SERVFAIL was returned (shouldn't happen); if so the actual
#               error is written to the file new-errors-MXqueries.txt
##############################################################################
sub checkMX{

   my ($self, @dToQuery) = @_;

   my ($request, $status, %resultSet, $resultsHashRef);
   my $kdHashRef = $self->_getKDHashRef;
   print "SUB CHECKMX:  Known Domains hash REF in checkMX is: $kdHashRef\n" if $self->getDEBUG;

   foreach $request(@dToQuery){
      print "$request **********START \n" if $self->getDEBUG;
      if( exists( $kdHashRef->{$request} )  ){
      ##### if the domain is in the list of known domains we may not have to check it.
         if($kdHashRef->{$request} eq $self->get_UNCHECKED(0)){
         ##### if request has NOT been previously checked, check it and assign new status
            $status = $self->lookUp($request);
            $kdHashRef->{$request}=$status;
            print "Known Domains changed: $request => " . $kdHashRef->{$request}."\n" if $self->getDEBUG;
            print "\t$request in KnownDomains: status set to $status\t\tEND******* \n" if $self->getDEBUG;
         }else{   
         ###### if request has been previously checked,  use the previously assigned status
            $status = $kdHashRef->{$request};
            print "\t$request in KnownDomains: status set to $status\t\tEND******* \n" if $self->getDEBUG;
         }
       }else{
       ###### if request is not in known domains,  perform lookup to set status
         $status = $self->lookUp($request);
         print "\t$request NOT in KnownDomains: status set to $status\t\tEND******* \n" if $self->getDEBUG;
       }
         $resultSet{$request}=$status;
   }
   $resultsHashRef = \%resultSet;
   if ($#dToQuery == 0){
   ##### if domains are being checked one domain at a time, return only the status
print "Returning $status\n"  if $self->getDEBUG;
      return $status;
   }else{
   ###### if a list of domains is being checked, return a hash of domainName => status
print "Returning $resultsHashRef"  if $self->getDEBUG;
      return $resultsHashRef;
   }
}




#  sub lookUp  checks one domain at a time for the existance of a mail exchange
#      by querying the internet.  It returns the status of the mail exchange.
#      If the status is not one currently programmed in this module, this
#      routine writes an entry into the file new-errors-MXQueries.txt 
#      consisting of the "[date time] | domain name | actual error message"
#
#      This routine may be useful for adhoc queries of a domain name  
#      BUT it will bypass loading and checking the 100 most used domains
#      and it can check only one domain at a time.
#
#  Params:  1: reference to self as object
#           2: A domain name string
#  Returns: The status of the domain as a string.  
#
#  Status Values returned:
#          UP = Indicates a mail exchange exists and is accessible.
#    NXDOMAIN = Indicates that there is no mail exchange for a domain name.
#    SERVFAIL = Indicates that there was some technical problem checking
#               for the mail exchange.  The exchange may exist, just be off line.
#    NOERROR  = Indicates that no mail exchange information was returned from
#               the query even though no error messages were encountered.
#               Also returned when new errors (errors other than NXDOMAIN
#               and SERVFAIL) are received.
################################################################################
sub lookUp{
   my ($self, $domain) = @_;
   my($res, $rr, $preference, $exchange, $errorString, $status, $query);
   my $newErrorsHashRef = $self->get_NewErrors();

   print "Working on: $domain \t\t\t$domain\nrecursion flag: ", $self->{resolver}->recurse, "  self:  self\n" if $self->{resolver} and $self->getDEBUG;

#  This section of commented out code returns IP Addresses for the domain name
#  which is not really needed for MAIL Exchange validation.
###########################################################
#   $query = $res->search($domain);
#      print "\tAssociated IP Addresses:\n" if $self->getDEBUG;
#      if ($query) {
#         foreach $rr ($query->answer) {
#            next unless $rr->type eq "A";
#            print "\t\t", $rr->address, "\n" if $self->getDEBUG;
#         }
#      } else {
#      print "\t\tquery failed: ", $res->errorstring, "\t(status not set here)\n" if $self->getDEBUG;
#      }

      # look up Mail Exchange
      print "\tAssociated Mail Exchanges:\n" if $self->getDEBUG;

            # if there's a resolver set, use it, otherwise use the default
      my @mx;
      my $resolver = $self->{resolver};

            if($resolver)
            {
        @mx = mx($resolver, $domain);
            }
            else
            {
        @mx = mx($domain);
            }

      if (@mx) {
         foreach $rr (@mx) {
            print "\t\t  ", $rr->preference, " ", $rr->exchange, "\n" if $self->getDEBUG;
            $preference =  $rr->preference();
            $exchange =  $rr->exchange();
         }
         $status = $self->get_AVAILABLE(0);
      }
            elsif($resolver) {
         print "\t\tcannot find MX records for $domain: ", $resolver->errorstring, "\t\n" if $self->getDEBUG;
         $errorString = $resolver->errorstring ;
         $status = $resolver->errorstring;
      }

      if(not $status or $status ne $self->get_AVAILABLE(0)     ){
         if   ($errorString and ($errorString eq $self->get_NODOMAIN(1)) ){ $status = $self->get_NODOMAIN(0) }
         elsif($errorString and ($errorString eq $self->get_SERVFAIL(1)) ){ $status = $self->get_SERVFAIL(0) } 
         elsif($errorString and ($errorString eq $self->get_UNCLEAR(1))  ){ $status = $self->get_UNCLEAR(0)  }
         else{                                          $status = $self->get_UNCLEAR(0); 
            if( $self->getNewErrorsFlag() ){
               $newErrorsHashRef->{$domain} = $errorString;
               print "New Error Encountered:  $domain => $errorString\n" if $self->getDEBUG;
            }
         }
      print "Status assigned is: $status\n" if $self->getDEBUG;
      }
   return $status;
}
#  get_newErrors   returns a hash of domainNames => errorCodes
#                  of responses to our inquiry (lookup MX) that do not 
#                  matchexpect values  (the error returned was unexpected)
#
#  Params  NONE  however this the hash will be empty if the proper Params 
#          were not passed to new()  [new(fileHandle,updateFlag,collectNewErrorsFlag)]
################################################################################

#######################################################################################
return 1;
END { }
