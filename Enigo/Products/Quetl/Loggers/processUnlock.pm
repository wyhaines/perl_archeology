#!perl
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: processUnlock.pm

=head1

I<REVISION: 1>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: 23 Mar 2001>

=head1 PURPOSE:

Unlocks a client/table pair in the process_lock table.

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

sub processUnlock {
  my ($param) = paramCheck([DBH => 'U',
                            CLIENT => 'U',
                TABLE => 'U'],@_);

  eval {
    my $sth = $param->{DBH}->prepare(<<ESQL);
update stage.process_lock
set dc_load='N',
dc_load_date=sysdate
where client = ? and table_name = ?
ESQL
    $sth->execute($param->{CLIENT},$param->{TABLE});
    $param->{DBH}->commit();
  };

  return $@ ? undef : 1;
}
1;
