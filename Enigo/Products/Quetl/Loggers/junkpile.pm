#!perl
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: junkpile.pm

=head1

I<REVISION: 1>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: 13 Mar 2001>

=head1 PURPOSE:

If there is file data that can not be written out to a "correct"
location, either because there is something wrong with the data
that impairs the ability of the code to find a correct location,
or because of a permissions problem or other error in writing,
junkpile() can be used to make sure that the data does go
someplace.

It will attempt to write the file to a junkpile/ directory
relative to the dw_home.  If THAT fails, it will log the error and
will write the data out to /tmp/Quetl_junkpile/.  If that fails,
then the code will log that error and will have no choice but to
bail out, causing the data to go to the bit bucket.

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

sub junkpile {
  my ($param) = paramCheck([SERVER => 'AN',
                PATH => 'U',
                DATA => 'U',
                DW_HOME => 'U'],@_);

  my $dw_home = exists $param->{DW_HOME} ? $param->{DW_HOME} : $ENV{DW_HOME};
  $dw_home = $dw_home ? $dw_home : '/opt/dw';

  $param->{PATH} =~ s{^\s*/}{};
  my $relative_path = "junkpile/$param->{SERVER}/$param->{PATH}";

  eval {
    mkdirs({PATH => "$dw_home/$relative_path"});
    open(JUNKPILE,">>$dw_home/$relative_path") or die;
    print JUNKPILE $param->{DATA};
    close JUNKPILE;
    logError({DETAILS => "Data from $param->{SERVER}:$param->{PATH} has been written to $dw_home/$relative_path."});
  };

  if ($@) {
    eval {
      my $err = $@;
      $@ = undef;
      mkdirs({PATH => "/tmp/Quetl_junkpile/$relative_path"});      
      open(JUNKPILE,">>/tmp/Quetl_junkpile/$relative_path") or die;
      print JUNKPILE $param->{DATA};
      close JUUNKPILE;
      logError({DETAILS => "$err\n\nData from $param->{SERVER}:$param->{PATH} has been written to /tmp/Quetl_junkpile/$relative_path."});
    };

    if ($@) {
      logError
    ({DETAILS => "$@\n\nData from $param->{SERVER}:$param->{PATH} could not be written and has been lost."});
    }
  }
}


1;
