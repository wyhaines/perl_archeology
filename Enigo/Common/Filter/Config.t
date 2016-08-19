#!/usr/bin/perl

use strict;

use Enigo::Common::Override {exit => ['Enigo::Common::Exception']};
use Enigo::Common::Filter qw(Config);
use IO::Scalar;
use Algorithm::Diff;
use Text::Wrap;
use Error qw(:try);

print "Testing Enigo::Common::Filter::Config filters\n\n";

my @tests = split(/;;;;;/,<<'ETESTS');
my $code;
my $base_code = $code = <<ECODE;
print "Running on ",[!--hostname--]," host.\n";
ECODE
eval {
  $code = Enigo::Common::Filter->filter($code);
};
eval $code;
check("[!--hostname--] filter works.",
      ($code eq $base_code),
      diff($code,$base_code));
;;;;;
my $code;
my $base_code = $code = <<ECODE;
[!--date today--] > [!--date today at noon--]
ECODE
eval {
  $code = Enigo::Common::Filter->filter($code);
};
my $result = eval $code;
print "Is it currently before or after noon?\n";
if ($result) {
  print "  after\n";
} else {
  print "  before\n";
}
check("[!--date today--] > [!--date today at noon--] filter works.",
      ($code eq $base_code),
      diff($code,$base_code));
;;;;;
my $code;
my $base_code = $code = <<ECODE;
print "Running on ",[!--machtype--]," machine.\n";
ECODE
eval {
  $code = Enigo::Common::Filter->filter($code);
};
eval $code;
check("[!--machtype--] filter works.",
      ($code eq $base_code),
      diff($code,$base_code));
;;;;;
my $code;
my $base_code = $code = <<ECODE;
print "Running on ",[!--ostype--]," OS.\n";
ECODE
eval {
  $code = Enigo::Common::Filter->filter($code);
};
eval $code;
check("[!--ostype--] filter works.",
      ($code eq $base_code),
      diff($code,$base_code));
;;;;;
my $code;
breakpoint();
my $base_code = $code = <<ECODE;
print "Running from ",[!--env PWD--]," with shell ",[!--env SHELL--],".\n";
ECODE
eval {
  $code = Enigo::Common::Filter->filter($code);
};
eval $code;
check("[!--env XXX--] filter works.",
      ($code eq $base_code),
      diff($code,$base_code));
ETESTS
    

print "1..",scalar(@tests),"\n";
my $test_num;

foreach my $test (@tests)
  {
    eval($test);
    if ($@)
      {
        $test_num++;
        print "FATAL ERROR\n";
        print "$@\nnot ok $test_num\n$!";
      }
  }

{
  $test_num = 0;
  sub check
    {
      my $description = shift;
      my $rc = shift;
      my $failure_information = shift;
      $test_num++;
      print Text::Wrap::wrap('','    ',"$description\n");
      unless ($rc)
        {
          print "ok $test_num\n";
        }
      else
        {
          if (defined $failure_information)
            {
              print <<ETXT;
*****************************
    Failed test returned:
$failure_information
*****************************
ETXT
            }
          print "not ok $test_num\n";
        }
    }
}


sub diff
  {
    my $s1 = [split(/\n/,shift)];
    my $s2 = [split(/\n/,shift)];

    my $diffs = Algorithm::Diff::diff($s1,$s2);
    my $result;

    foreach my $chunk (@{$diffs})
      {
        foreach my $line (@{$chunk})
          {
            my ($sign, $lineno, $text) = @{$line};
            $result .= sprintf "%4d$sign %s\n", $lineno+1, $text;
          }
        $result .= "--------\n";
      }

    return $result;
  }

sub breakpoint {print $main::fifi++,"\n";return $main::fifi;}
