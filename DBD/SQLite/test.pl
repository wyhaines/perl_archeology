use DBI;
use lib('/opt/enigo/common/perl');
use Enigo::lib('/opt/enigo/lib/perl5');

BEGIN {
  $| = 1;
  @tests = split(/;;;;;/,<<'ETESTS');
use vars qw($db);
eval {
  $db = DBI->connect('dbi:SQLite:griswald;666');
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
eval {
  my $rv = $db->do("create table tests (name char(20) primary key,result char(20))");
};

check("A database table can be created.",
      ($@ or $DBI::errstr),
      join("\n\n",$DBI::errstr,$@));
;;;;;
my $rv;
my %data = (version => 'ok',
            create => 'ok',
            populate => 'ok',
            select => 'ok',
            bind => 'ok',
            performance => 'ok',
            close => 'ok',
            artificial_intelligence => 'not ok');
eval {
  foreach my $k (keys %data) {
    $rv = $db->do("insert into tests (name,result) values ('$k','$data{$k}')");
  }
};

check("A table can be populated with data.",
      $@,
      $@);
;;;;;
my $rv;
eval {
  print "select * from tests\n";
  my $sth = $db->prepare("select * from tests");
  $sth->execute();
  while (my $row = $sth->fetchrow_arrayref()) {
    print "$row->[0] / $row->[1]\n";
  }
};

check("Data can be queried from a table.",
      $@,
      $@);
;;;;;
my $rv;
eval {
  print "select * from tests where result = ?\n";
  print "? == 'ok'\n\n";
  my $sth = $db->prepare("select * from tests where result = ?");
  $sth->execute('ok');
  while (my $row = $sth->fetchrow_arrayref()) {
    print "$row->[0] / $row->[1]\n";
  }
  print "select * from tests where name = ?\n";
  $sth = $db->prepare("select * from tests where name = ?");
  $sth->execute('populate');
  while (my $row = $sth->fetchrow_arrayref()) {
    print "$row->[0] / $row->[1]\n";
  }
};

check("Data can be queried from a table while employing bind variables.",
      $@,
      $@);
;;;;;
my $rv;
eval {
  print "select * from tests where result = :1 and name = :2\n";
  print ":1 == 'ok'\n";
  print ":2 == 'version'\n\n";
  my $sth = $db->prepare("select * from tests where result = :1 and name = :2");
  $sth->execute('ok','version');
  while (my $row = $sth->fetchrow_arrayref()) {
    print "$row->[0] / $row->[1]\n";
  }
};

check("Data can be queried from a table while employing multiple positional bind variables.",
      $@,
      $@);
;;;;;
my $rv;
eval {
  print "select * from tests where result = :1 or name = ?\n";
  print ":1 == 'not okay'\n";
  print "? == 'version'\n\n";
  my $sth = $db->prepare("select * from tests where result = :1 or name = ?");
  $sth->execute('not ok','version');
  while (my $row = $sth->fetchrow_arrayref()) {
    print "$row->[0] / $row->[1]\n";
  }
};

check("Data can be queried from a table while employing positional and nonpositional bind variables.",
      $@,
      $@);
;;;;;
my $rv;
eval {
  print "select * from tests where name = :1 or name = :2\n";
  print ":1 == ':2'\n";
  print ":2 == 'artificial_intelligence'\n\n";
  my $sth = $db->prepare("select * from tests where name = :1 or name = :2");
  $sth->execute(':2','artificial_intelligence');
  while (my $row = $sth->fetchrow_arrayref()) {
    print "$row->[0] / $row->[1]\n";
  }
};

check("Data can be queried from a table when one parameter itself contains :\d+ type data.",
      $@,
      $@);
;;;;;
my $rv;
eval {
  print "select * from tests where name = :1 or name = :2\n";
  print ":1 == ':1'':2'\n";
  print ":2 == 'artificial_intelligence'\n\n";
  my $sth = $db->prepare("select * from tests where name = :1 or name = :2");
  $sth->execute(":1'':2",'artificial_intelligence');
  while (my $row = $sth->fetchrow_arrayref()) {
    print "$row->[0] / $row->[1]\n";
  }
};

check("Data can be queried from a table when one parameter itself contains :\d+ type data, and that parameter also contains sql escaped quotes ('').",
      $@,
      $@);
;;;;;
my $rv;
eval {
  print "select * from tests where result = :2 or name = :1\n";
  print ":2 == 'not okay'\n";
  print ":1 == 'version'\n\n";
  my $sth = $db->prepare("select * from tests where result = :2 or name = :1");
  $sth->execute('version','not ok');
  while (my $row = $sth->fetchrow_arrayref()) {
    print "$row->[0] / $row->[1]\n";
  }
};

check("Data can be queried from a table when the positional params are out of order.",
      $@,
      $@);
;;;;;
my $rv;
eval {
  $rv = $db->do('drop table tests');
};

check("A table can be dropped.",
      ($@ or $DBI::errstr),
      join("\n\n",$DBI::errstr,$@));
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
  $rv = $db->do("create table words (word char(100) primary key,number char(7))");
  print "Populating a table...\n";
  my $count = 0;
  my $start_time = time();
  open(WORDS,"<$wordlist");
  while (my $word = <WORDS>) {
    chomp($word);
    $count++;
    my $sth = $db->prepare("insert into words (word,number) values (:1,:2)");
    my $rv = $sth->execute($word,$count);
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
my $start_time = time();
open(WORDS,"<$wordlist");
while (my $word = <WORDS>) {
  chomp($word);
  $count++;
  my $sth = $db->prepare("select number from words where word = :1");
  $sth->execute($word);
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
my $rv;
my $start_time = time();
eval {
  $rv = $db->do("delete from words");
};

my $end_time = time();
my $difference = $end_time - $start_time;
$difference = $difference ? $difference : 1;
my $rate = 4000 / $difference;
print "Deleted 4000 records in $difference seconds ($rate records per second).\n";
 
check("Massive number of deletes works.",
      $@,
      $@);
;;;;;
eval {
  $db->disconnect();
  $db = undef;
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
