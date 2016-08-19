#!/usr/bin/perl -wc
# 
######################################################################
##### Header
######################################################################
=pod

=head1 FILE_NAME: DBI.pm

=head1 Enigo::Common::DB::DBI;

I<REVISION: 1.5>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: 14:16 31 Oct 2000>

=head1 PURPOSE:

This class inherits from DBI to provide some additional functionality.

It currently overrides connect() in order to store the AUTH parameter
used to connect to a database as a private attribute.  It is also
being expanded to provide execption throwing versions of the DBI
methods.

=head1 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################
package Enigo::Common::DB::DBI;

use strict;

use DBI;
#use DBD::Oracle;
use Enigo::Common::Exception qw(:DB :general);

use vars qw($VERSION @ISA);
@ISA = qw(DBI);
$VERSION = '1.5';

######################################################################
##### Method: connect
######################################################################

=pod

=head2 METHOD_NAME: connect

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 22 JUN 2000>

=head2 PURPOSE:

Overrides DBI::connect to store the AUTH used to connect to the
database within a private attribute.  Also traps DBI::connect
errors and throws exceptions based on these.

=head2 ARGUMENTS:

See the L<DBI> POD.

=head2 RETURNS:

See the L<DBI> POD.

=head2 THROWS:

  Enigo::Common::Exception::IO::DB::CouldNotConnect

=head2 EXAMPLE:

  try
    {
      $dbh = Enigo::Common::DB::DBI->connect($dsn,$user,$auth);
    }
  catch Enigo::Common::Exception::IO::DB with
    {
      my $exception = shift;
      $exception->fatal();
    };

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################
sub connect
  {
    my($dsn, $user, $pass, $attr, $old_driver, $connect_meth) = @_;

    my $dbh;
    eval
      {
    $dbh = DBI::connect(@_);
      };
    if ($@)
      {
    my $general_exception = _general_exception($@);

    my $db_exception =
      Enigo::Common::Exception::IO::DB::CouldNotConnect->new
        ({DSN => $dsn,
          USER => $user,
          AUTH => $pass});

    $db_exception->attach($general_exception);
    throw $db_exception;
      }
    else
      {
    $dbh->{private_AskAround_DB_DBI_AUTH} = $pass;
    return $dbh;
      }
  }


*DBD::Oracle::db::enigo_override_prepare = \&DBD::Oracle::db::prepare;
{
  local $^W = 0;
  *DBD::Oracle::db::prepare = \&prepare;
}

sub prepare
  {
    my $self = $_[0];
    my $statement;
    eval
      {
    $statement = DBD::Oracle::db::enigo_override_prepare(@_);
      };
    if ($@ or !$statement)
      {
    my $general_exception = _general_exception($@) if $@;

    my $db_exception =
      Enigo::Common::Exception::IO::DB::PrepareFailed->new
        ({DBH => $self,
          SQL => $_[1]});

    $db_exception->attach($general_exception) if $@;
    throw $db_exception;
      }
    else
      {
    return $statement;
      }
  }



sub _general_exception
  {
    my $text = shift;
    return Enigo::Common::Exception::General->new
      (
       {TYPE => 'DBIError',
    TEXT => $text});
  }


######################################################################
##### Method: execute
######################################################################

=pod

=head2 METHOD_NAME: execute

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 22 JUN 2000>

=head2 PURPOSE:

Overrides DBI::st::execute() in order to provide for throwing
exceptions on execute failure.

=head2 ARGUMENTS:

See the L<DBI> POD.

=head2 RETURNS:

See the L<DBI> POD.

=head2 THROWS:

  Enigo::Common::Exception::IO::DB::ExecuteFailed

=head2 EXAMPLE:

  try
    {
      $sth->execute(@bindvars);
    }
  catch Enigo::Common::Exception::IO::DB with
    {
      my $exception = shift;
      $exception->fatal();
    };

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################
#This code is executed when the module is 'use'd.  It stores the
#original destination of DBI::st::execute() in
#DBI::st::enigo_override_execute(), and then uses DBI::st::execute()
#to store the hook into our overriding method.  The overriding
#is done in this manner because DBI::st is setup programatically
#within DBI, and it would be an ugly, ugly thing to attempt
#to subclass DBI to override how it sets up DBI::st.  Much
#uglier than this little hack.
*DBI::st::enigo_override_execute = \&DBI::st::execute;
{
  local $^W = 0;
  *DBI::st::execute = \&execute;
}

sub execute
  {
    my $self = shift;

    eval
      {
    $self->enigo_override_execute(@_);
      };
    if ($@)
      {
    my $general_exception = _general_exception($@);

    my $db_exception =
      Enigo::Common::Exception::IO::DB::ExecuteFailed->new
        ({STH => $self,
          PARAMS => \@_});

    $db_exception->attach($general_exception);
    throw $db_exception;
      } 
  }



1;
