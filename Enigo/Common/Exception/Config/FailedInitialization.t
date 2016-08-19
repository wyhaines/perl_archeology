#!/usr/bin/perl

use strict;

use Enigo::Common::Override {exit => ['Enigo::Common::Exception']};
use Enigo::Common::Exception::Config::FailedInitialization;
use IO::Scalar;
use Algorithm::Diff;

print "Testing Enigo::Common::Exception::Config::FailedInitialization\n\n";

my $config = 'TestError';
my $derived_config;
my $catalog = '/usr/local/share/catalog';
my $derived_catalog;

my $eval_error;
my $exception;

my @tests = split(/;;;;;/,<<'ETESTS');
eval
  {
    $exception = new Enigo::Common::Exception::Config::FailedInitialization
      ($catalog,$config);
  };
check('new() throws no errors with list arguments.',
      $@,
      $@);
;;;;;
eval
  {
    sub testit
      {
        local $Error::Debug = 1;
        $exception = new Enigo::Common::Exception::Config::FailedInitialization
          ({CATALOG => $catalog,
            CONFIG => $config,
            VALUE => 69});
      }
    &testit();
  };
check('new() throws no errors with hashref arguments.',
      $@,
      $@);
;;;;;
check('new() returns an object blessed into the correct class.',
      ref($exception) ne 'Enigo::Common::Exception::Config::FailedInitialization');
;;;;;
check('stringify() returns a correctly formatted error message.',
      $exception->stringify() !~
        /^\w+:\s*\w+:\s*.+?config\scatalog,\s+(.+?),.+?config,\s+(.+?),/s,
      $exception->stringify());
      $derived_catalog = $1;
      $derived_config = $2;
;;;;;
check('The expected database information is returned in the error message.',
      !($derived_catalog eq $catalog and $derived_config eq $config),
      join('',
           "Error catalog:\n\n",diff($derived_catalog,$catalog),"\n\n",
           "Error config:\n\n",diff($derived_config,$config),"\n\n"));
;;;;;
check('The expected stacktrace is generated when $Error::Debug is set.',
      $exception->stringify() !~
        /Stack Trace\s*-----------\s*Error at /s,
      $exception->stringify());
;;;;;
tie(*STDERR,'IO::Scalar');
my $error = $exception->nonfatal();
untie *STDERR;
check('nonfatal() returns the expected error message.',
      $exception->stringify() ne $error,
      diff($exception->stringify(),$error));
;;;;;
tie(*STDERR,'IO::Scalar');
Enigo::Common::Override->override(exit => sub{return @_});
$exception->fatal();
Enigo::Common::Override->restore('exit');
tied(*STDERR)->seek(0,0);
my $stderr_txt = join('',(tied(*STDERR)->getlines()));
untie *STDERR;
my $stringified_txt = $exception->stringify();
$stderr_txt =~ s/\s*$//g;
$stringified_txt =~ s/\s*$//g;
check('fatal() returns the expected error message.',
       $stringified_txt ne $stderr_txt,
       diff($stringified_txt,$stderr_txt));
ETESTS
    

print "1..",scalar(@tests),"\n";
my $test_num;

foreach my $test (@tests)
  {
    eval($test);
    if ($@)
      {
        $test_num++;
        print "$@\nnot ok $test_num\n";
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
      print "$description\n";
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
