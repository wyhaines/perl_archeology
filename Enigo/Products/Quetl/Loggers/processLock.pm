#!perl
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: processLock.pm

=head1

I<REVISION: 1>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: 23 Mar 2001>

=head1 PURPOSE:

Checks the process_lock table in order to determine if the ETL
process should be allowed to continue, and while checking, it
also updates the table so that the subject builder is informed
that something is loading, and won't itself start running while
new data is being actively loaded into a stage table.

Expects a hash reference with three keys, the DBH to use, the
CLIENT that we are checking on behalf of, and the TABLE that
we want to load data into.

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
use Data::Dumper;

sub processLock {
  my ($param) = paramCheck([DBH => 'U',
                            CLIENT => 'U',
                TABLE => 'U'],@_);

  my $sth;
  my $dc_load;
  eval {
    $sth = $param->{DBH}->prepare(<<ESQL);
select dc_load
from stage.process_lock
where client = ? and table_name = ?
ESQL
    $sth->execute($param->{CLIENT},$param->{TABLE});

    ($dc_load) = $sth->fetchrow_array();
  };

  unless ($dc_load) {
    eval {
      $sth = $param->{DBH}->prepare(<<ESQL);
insert into stage.process_lock
(client,table_name,dc_load,dc_load_date,sb_lock,sb_lock_date,sb_ok) values
(?,?,?,sysdate,?,sysdate,?)
ESQL

      $sth->execute($param->{CLIENT},
                    $param->{TABLE},
                    'N',
                    'N',
                    'Y');
      $param->{DBH}->commit();
    };
  }

  eval {
    my $sth = $param->{DBH}->prepare(<<ESQL);
update stage.process_lock
set dc_load='Y',
dc_load_date=sysdate
where client = ? and table_name = ?
ESQL
    $sth->execute($param->{CLIENT},$param->{TABLE});
    $param->{DBH}->commit();
  };

  return undef if $@;

  my $locked;
  eval {
    my $sth = $param->{DBH}->prepare(<<ESQL);
select sb_lock
from stage.process_lock
where client = ? and table_name = ?
ESQL
    $sth->execute($param->{CLIENT},$param->{TABLE});
    ($locked) = $sth->fetchrow_array();
  };

  if ($locked =~ /Y/i) {
    processUnlock({DBH => $param->{DBH},
                   CLIENT => $param->{CLIENT},
                   TABLE => $param->{TABLE}});
    return undef;
  } else {
    return "$param->{CLIENT}/$param->{TABLE} locked";
  }
}
1;
