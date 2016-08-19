#!/usr/bin/perl

use strict;

use Enigo::Common::Override {exit => ['Enigo::Common::Exception']};
use Enigo::Common::Exception::IO::DB;
use IO::Scalar;
use Algorithm::Diff;

print "Testing Enigo::Common::Exception::IO::DB\n\n";

my $text = "The database is down";
my $derived_text;
my $eval_error;
my $exception;

my @tests = split(/;;;;;/,<<'ETESTS');
eval
  {
    $exception = new Enigo::Common::Exception::IO::DB
      ($text);
  };
check('new() throws no errors with list arguments.',
      $@);
;;;;;
eval
  {
    sub testit
      {
        local $Error::Debug = 1;
        $exception = new Enigo::Common::Exception::IO::DB
          ({TEXT => $text,
            VALUE => 69});
      }
    &testit();
  };
check('new() throws no errors with hashref arguments.',
      $@);
;;;;;
check('new() returns an object blessed into the correct class.',
      ref($exception) ne 'Enigo::Common::Exception::IO::DB');
;;;;;
check('stringify() returns a correctly formatted error message.',
      $exception->stringify() !~
        /^\w+:\s*\w+:\s(.+?)\n/s,
      $exception->stringify());
      $derived_text = $1;
;;;;;
check('The expected database information is returned in the error message.',
      !($derived_text eq $text),
      join('',
           "Error text:\n\n",diff($derived_text,$text),"\n\n"));
;;;;;
check('The expected stacktrace is generated when $Error::Debug is set.',
      $exception->stringify() !~
        /Stack Trace\s*-----------\s*Error at /s,
      $exception->stringify());
;;;;;
tie(*STDERR,'IO::Scalar');
my $text = $exception->nonfatal();
untie *STDERR;
check('nonfatal() returns the expected error message.',
      $exception->stringify() ne $text,
      diff($exception->stringify(),$text));
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
