BEGIN {
  $| = 1;
  @tests = split(/;;;;;/,<<'ETESTS');
my $version;
eval {
  $version = sqlite::version();
};
check("The SQLite library version($version) can be queried.",
      ($@),
      $@);
;;;;;
my $encoding;
eval {
  $encoding = sqlite::encoding();
};
check("The SQLite default encoding($encoding) can be queried.",
      ($@),
      $@);
;;;;;
use vars qw($db);
eval {
  $db = sqlite::open_db('griswald',666);
};
my $fail_message;
if ($@) {
  $fail_message = $@;
} elsif (! ref $db) {
  $fail_message = $db;
}
check("A database can be opened/created/",
      $fail_message,
      $fail_message);
;;;;;
my $rv;
eval {
  $rv = sqlite::exec_sql($db,
                         "create table tests (name char(20) primary key,result char(20))",sub {undef},'');
};

check("A database table can be created.",
      $rv->[0],
      join("\n\n",$rv->[1],$@));
;;;;;
my $rv;
my %data = (version => 'ok',
            create => 'ok',
            populate => 'ok');
eval {
  foreach my $k (keys %data) {
    $rv = sqlite::exec_sql($db,"insert into tests (name,result) values ('$k','$data{$k}')",sub {undef},'');
  }
};

check("A table can be populated with data.",
      $@,
      $@);
;;;;;
sub main::callback {
print STDERR "in callback...\n";
  
print Dumper(@_);
return undef;
}
my $rv;
eval {
  $rv = sqlite::exec_sql($db,"select * from tests",\&main::callback,'');
};

check("Data can be queried from a table.",
      $@,
      $@);
;;;;;
my $rv;
eval {
  $rv = sqlite::exec_sql($db,"drop table tests",sub {undef},'');
};

check("A table can be dropped.",
      $rv->[0],
      $rv->[1]);
;;;;;
my $rv;
use vars qw($wordlist);
if (-e '/usr/share/dict/words') {
  $wordlist = '/usr/share/dict/words';
} elsif (-e '/usr/share/lib/dict/words') {
  $wordlist = '/usr/share/lib/dict/words';
}
unless ($wordlist) {
  my @words;
  open(WORDS,"<miniwords");
  while (my $word = <WORDS>) {
    push(@words,$word);
  }
  close WORDS;
  open(WORDS,">megawords");
  for(my $k = 0;$k < scalar(@words);$k++) {
    foreach my $word (@words) {
      print WORDS join('',$word,$words[$k],"\n");
    }
  }

  close WORDS;
  $wordlist = "megawords";
}

eval {
  $rv = sqlite::exec_sql($db,"create table words (word char(100) primary key,number char(7))",sub {undef},'');
  print "Populating a table...\n";
  my $count = 0;
  my $start_time = time();
  open(WORDS,"<$wordlist");
  while (my $word = <WORDS>) {
    chomp($word);
    $count++;
    $rv = sqlite::exec_sql($db,"insert into words (word,number) values ('$word',$count)",sub {undef},'');
    print "    $count...\n" unless ($count % 500);
    last if ($count == 4000);
  }
  close WORDS;

  my $end_time = time();
  my $difference = $end_time - $start_time;
  my $rate = $count / $difference;
  print "Inserted $count rows in $difference seconds ($rate rows per second).\n"; 
};

check("Massive set of inserts works.",
      $@,
      $@);
;;;;;
print "Selecting from the table (in order)...\n";
my $count = 0;
my $rv;
my $start_time = time();
open(WORDS,"<$wordlist");
while (my $word = <WORDS>) {
  chomp($word);
  $count++;
  $rv = sqlite::exec_sql($db,"select number from words where word = '$word'",sub {undef},'');
  print "    $count...\n" unless ($count % 500);
  last if ($count == 4000);
}
close WORDS;

my $end_time = time();
my $difference = $end_time - $start_time;
my $rate = $count / $difference;
print "Selected $count records in $difference seconds ($rate records per second).\n";

check("Massive number of selects works.",
      $@,
      $@);
;;;;;
eval {
  sqlite::close_db($db);
};

check("The database can be closed.",
      $@,
      $@);
ETESTS

  print "Testing sqlite.\n\n";
  print "1..",(scalar(@tests) + 1),"\n";
}

END {
  print "not ok 1\n" unless $loaded;
  system("rm -rf griswald") if $loaded;
}

use sqlite;
$loaded = 1;
print "ok 1\n";

use strict;
use vars qw(@tests);

use Algorithm::Diff;
use Text::Wrap;
use Data::Dumper;

my $test_num = 1;

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
