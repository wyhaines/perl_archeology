#!/usr/bin/perl

use strict;

use AA::Common::Override {exit => ['AA::Common::Exception']};
use AA::Common::SQL::SQL;
use IO::Scalar;
use Algorithm::Diff;

print "Testing AA::Common::SQL::SQL\n\n";

$ENV{'CONFIG_CATALOG'} = '/usr/AA/config/catalog';
$ENV{'CONFIG'} = 'AskAround';

my $sql;
my $dbh;
my $dbh2;
my $sth;
my $exception;

my @tests = split(/;;;;;/,<<'ETESTS');
eval
  {
    $sql = AA::Common::SQL::SQL->new({ATTRIB => {AutoCommit => 1,
                                                PrintError => 0}}); 
  };
check('A new AA::Common::SQL::SQL object can be created.',
      $@,
      $@);
;;;;;
check('get_dbh() properly returns the raw database handle.',
      !(ref($sql->get_dbh()) eq 'DBI::db'),
      ref($sql->get_dbh()));
$dbh = $sql->get_dbh();
$sth = $dbh->prepare("create table test_table_$$ (col1 number,col2 char(1))");
$sth->execute();
;;;;;
eval
  {
    $dbh2 = $sql->get_dbh({ATTRIB => {AutoCommit => 0}});
  };
check('get_dbh() returns a new database handle when given new attributes.',
      $dbh eq $dbh2);
;;;;;
my $param;
eval
  {
    $param = $sql->get_param($dbh);
  };
check('get_param() returns what is expected.',
      !($param->{ATTRIB}->{AutoCommit} == 1 and
        $param->{ATTRIB}->{PrintError} == 0),
      join("\n",
           "{ATTRIB}->{AutoCommit} -- param->{ATTRIB}->{AutoCommit}",
           "{ATTRIB}->{PrintError} -- $param->{ATTRIB}->{PrintError}"));
;;;;;
my %params;
eval
  {
    %params = $sql->get_all_params();
  };
check('get_all_params() returns what is expected.',
      !(scalar(keys %params) == 2));
;;;;;
my $value;
eval
  {
    $value = $sql->scalar("select * from tab");
  };
check('scalar() query with multirow, multicolumn results is rejected.',
      !$@,
      $value);
;;;;;
my $value;
eval
  {
    $value = $sql->scalar("select 1,1 from dual");
  };
check('scalar() query with multicolumn results is rejected.',
      !$@,
      $value);
;;;;;
my $value;
eval
  {
    $value = $sql->scalar("select dual from dual");
  };
check('scalar() query with bad SQL is rejected.',
      !$@,
      $value);
;;;;;
my $value;
eval
  {
    $value = $sql->scalar("select 2 from dual");
  };
check('Single row, single column query to scalar() returns expected value.',
      $value != 2,
      diff('2',$value));
;;;;;
my @columns;
eval
  {
    @columns = $sql->row("select * from tab");
  };
check('Multicolumn, multirow row() query rejected.',
      !$@,
      join("\n",@columns));
;;;;;
my @columns;
eval
  {
    @columns = $sql->row("select 1,2,3,4 from dual");
  };
my $count = 0;
check('Multirow row() query returns expected values.',
      (scalar(grep {$_ ne $columns[$count++]} (1,2,3,4)) or
       scalar(@columns) != 4),
      join("\n",@columns));
;;;;;
my %hash;
eval
  {
    %hash = $sql->hash("select 1 as foo,2 as bar,3 as baz,4 as biz from dual");
  };
check('hash() query returns expected values.',
      !(join('', keys %hash)  eq 'FOOBARBAZBIZ'),
      join("\n",map {"$_ -- $hash{$_}"} keys %hash));
;;;;;
eval
  {
    foreach my $count (0..10)
      {
        $sql->insert("insert into test_table_$$ (col1,col2) values (?,?)",
                     ($count,chr($count + 65)));
      }
  };
check('insert() works to populate a table.',
      $@,
      $@);
;;;;;
my @list;
eval
  {
    @list = $sql->list("select col1 from test_table_$$ order by col1 asc");
  };
my $count = 0;
check('list() properly returns single column, multirow results.',
      (scalar(grep {$_ ne $list[$count++]} (0..10)) or
       scalar(@list) != 11),
      join("\n",@list));
;;;;;
my @list;
eval
  {
    @list = $sql->list("select col1,col2 from test_table_$$");
  };
check('list() properly rejects multicolumn, multirow results.',
      !$@,
      join("\n",@list));
;;;;;
my @list;
eval
  {
    @list = $sql->row_list
      ("select col1,col2 from test_table_$$ order by col1 asc");
  };
my $count = 0;
my $count2 = 0;
check('row_list() returns expected results for multirow, multicolumn query.',
      (scalar(@list) != 11 or
       scalar(grep {$_ ne $list[$count]->[0] or
                    chr($_ + 65) ne $list[$count++]->[1]} (0..10))),
      join("\n",
           map {"$list[$_]->[0] -- $list[$_]->[1]"} (0..10)));
;;;;;
my @list;
eval
  {
    @list = $sql->hash_list
      ("select col1,col2 from test_table_$$ order by col1 asc");
  };
my $count = 0;
my $count2 = 0;
check('hash_list() returns expected results for multirow, multicolumn query.',
      (scalar(@list) != 11 or
       scalar(grep {$_ ne $list[$count]->{COL1} or
                    chr($_ + 65) ne $list[$count++]->{COL2}} (0..10))),
      join("\n",
           map {"$list[$_]->{COL1} -- $list[$_]->{COL2}"} (0..10)));
;;;;;
my @list;
eval
  {
    $sql->delete("delete from test_table_$$ where col1 = ?",10);
    @list = $sql->hash_list
      ("select col1,col2 from test_table_$$ order by col1 asc");
  };
my $count = 0;
my $count2 = 0;
check('delete() successfully removes rows from a table.',
      (scalar(@list) != 10 or
       scalar(grep {$_ ne $list[$count]->{COL1} or
                    chr($_ + 65) ne $list[$count++]->{COL2}} (0..9))),
      join("\n",
           map {"$list[$_]->{COL1} -- $list[$_]->{COL2}"} (0..9)));

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

$sth = $dbh->prepare("drop table test_table_$$");
$sth->execute();
exit;

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
