#!/usr/bin/perl -wc
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: SQL.pm

Z<>

I<REVISION: $Revision: 1.1.1.1 $>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: $Date: 2001/12/17 02:28:37 $>

=head1 PURPOSE:

Provides a helper object for doing database accesses.

=head1 EXAMPLE:

=head1 TODO:

Document it better.

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

package Enigo::Common::SQL::SQL;

use strict;

use vars qw(%gDBH %gPARAM);

use Enigo::Common::DB::DBI;
use Enigo::Common::Config;
use Error qw(:try);
use Enigo::Common::Exception qw(:DB :general :Config);
require Enigo::Common::Exception::SQL;
require Enigo::Common::Exception::SQL::FailedGetDBH;
require Enigo::Common::Exception::SQL::InvalidDefaultDBH;
require Enigo::Common::Exception::SQL::BadScalarQuery;
require Enigo::Common::Exception::SQL::BadRowQuery;
require Enigo::Common::Exception::SQL::BadColumnQuery;
require Enigo::Common::Exception::SQL::FailedSQLStatement;

$ENV{ORACLE_HOME} = '/usr/local/oracle' unless exists $ENV{ORACLE_HOME};



######################################################################
##### Method: restartHandler
######################################################################

=pod

=head2 METHOD_NAME: restartHandler

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 15 July 2000>

=head2 PURPOSE:

An Apache restart handler that will make sure each of the existing
database handles is closed before a restart occurs.

=head2 ARGUMENTS:

none

=head2 THROWS:

nothing

=head2 RETURNS:

undef

=head2 EXAMPLE:

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub restartHandler {
  keys(%gDBH); #reset the hash itereator
  foreach my $dbh (values(%gDBH)) {
    $dbh->disconnect;
  }

  %gPARAM = {};
}



######################################################################
##### Constructor: new
######################################################################

=pod

=head2 COUNSTRUCTOR_NAME: new

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 15 July 2000>

=head2 PURPOSE:

To create and return an object of type SQL.

=head2 ARGUMENTS:

Can be used with or without parameters.  If used without parameters,
the database connect information is pulled from the configuration
specified in a config file.  The configuration file to use will either
be determined by the values of the 'CONFIG_CATALOG' and 'CONFIG'
environment values, or they can be passed into the new() invocation
using parameters of the same name (look at the examples below).
The constructor can also accept an already initialized Enigo::Common::Config
object via tha 'CONFIG_OBJECT' parameter.  If this parameter is
populated with an object, the constructor will use that rather than
creating a new one.
If an ATTRIB parameter is not specified (ATTRIB is a hash ref exactly
as DBI expects to see it), the default attribute set is simple to
set AutoCommit on. 

=head2 THROWS:

=head2 RETURNS:

=head2 EXAMPLE:

  $SQL = Enigo::Common::SQL::SQL->new();

  $SQL = Enigo::Common::SQL::SQL->new({ATTRIB => {AutoCommit => 1,
                                                  PrintError => 0}});

  $SQL = Enigo::Common::SQL::SQL->new({DSN => 'dbi:Oracle:webdb',
                                       USER => 'willaby',
                                       AUTH => 'wallaby',
                                       CONFIG_OBJECT => $CONFIG,
                                       ATTRIB => {AutoCommit => 0,
                              RaiseError => 0,
                          ChopBlanks => 1}});

  $SQL = Enigo::Common::SQL::SQL->new
    ({CONFIG_CATALOG => '/usr/Enigo/config/catalog',
      CONFIG => 'MyApp',
      DSN => 'dbi:Oracle:webdb',
      USER => 'willaby',
      AUTH => 'wallaby',
      ATTRIB => {AutoCommit => 0,
             RaiseError => 0,
             ChopBlanks => 1}});

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub new {
  my $proto = shift;
  my $param = shift;
  my $class = ref($proto) || $proto;
  my $self = {};

  bless $self, $class;

  $self->_init($param);

  return $self;
}


#%%
#% SUBROUTINE_NAME: _init
#% AUTHOR: Kirk Haines
#% PURPOSE: Initialize config items.
#% DATE_CREATED: 06 Jun 2000
#% NOTES: None
#% RETURNS: 
#    Nothing.
#% EXAMPLE: Private method.  No example.
#%%

sub _init {
  my $self = shift;
  my $param = shift;

  my $config;
  if (ref($param->{CONFIG_OBJECT}) =~ /config/i) {
    $config = $param->{CONFIG_OBJECT};
  } else {
    my $config_catalog = $param->{CONFIG_CATALOG} || $ENV{CONFIG_CATALOG};
    my $config_label = $param->{CONFIG} || $ENV{CONFIG};
    $config = Enigo::Common::Config->new();

    try {
      $config->parse($config_catalog);
      $config->read($config_label);
    } catch Enigo::Common::Exception with {
      my $exception = shift;
      my $config_exception = Enigo::Common::Exception::Config::FailedInitialization->new
    ({CATALOG => $config_catalog,
      CONFIG => $config_label});
      $config_exception->attach($exception);
      throw $config_exception;
    };
  }

  #If the $param value for one of the database connect values is
  #set, the $config-get() to be invoked at all.
  #However, if the $param value for DSN, USER, or AUTH, is not
  #set, the corresponding $config->get() will be invoked.
  #However, to allow for a case where we may not want a parameter,
  #probably AUTH, to be set at all, and thus don't pass it in and
  #don't have a config value for it, we catch exceptions thrown
  #by $config->get() and just ignore them.  If thatreally is a
  #problem, an exception will be thrown when the attempt to
  #connect to the database is made.
  my $dsn;
  try {
    $dsn = $param->{DSN} || $config->get('DSN');
  } catch Enigo::Common::Exception with {
    #NOP
  };

  my $user;
  try {
    $user = $param->{USER} || $config->get('USER');
  } catch Enigo::Common::Exception with {
    #NOP
  };

  my $auth;
  try {
    $auth = $param->{AUTH} || $config->get('AUTH');
  } catch Enigo::Common::Exception with {
    #NOP
  };

  my $dbh_key = $self->_dbh_key({DSN => $dsn,
                 USER => $user,
                 AUTH => $auth,
                 ATTRIB => $param->{ATTRIB}});

  $gDBH{$dbh_key} = $self->get_dbh({DSN => $dsn,
                    USER => $user,
                    AUTH => $auth,
                    ATTRIB => $param->{ATTRIB}});
  $self->{DEFAULT_DBH_KEY} = $dbh_key;
}


#%% 
#% SUBROUTINE_NAME: get_dbh
#% AUTHOR: Kirk Haines
#% PURPOSE: returns a dbh object useful for directly connecting to the database manually.
#  Takes as arguments a hashref containing DSN, USER, AUTH, and, optionally, ATTRIB
#  keys.  If given a set of attributes for a handle that already exists, that cached
#  handle will be returned.  Otherwise, get_dbh() will attempt to create and cache
#  a new handle using the specified parameters.
#
#  A shorthand, wherein only ATTRIB is given, is provided to facilitate the creation
#  of multiple handles that vary only by their attributes.  This shorthand specifies
#  that the current default handle's DSN, USER, and AUTH are to be used, along with
#  the ATTRIB provided as an argument.
#
#% DATE_CREATED: 2000/05/24
#% NOTES:
#% RETURNS: 
#     returns an object of type DBI
#% EXAMPLE: $SQL->get_dbh();  #Get the current default DBH
#
#           $SQL->get_dbh({DSN => 'dbi:Oracle:webdatabase',  #Get a DBH with these
#                          USER => 'Virginia',               #parameters, or create a
#                          AUTH => 'Dale'});                 #new one, if necessary.
#
#           $SQL->get_dbh({ATTRIB => {RaiseError => 1,       #Get/create a DBH with
#                                    {PrintError => 1}});    #default DSN, USER, AUTH,
#                                                            #but these attributes.
#%%                 

sub get_dbh {
  my $self = shift;
  my $param = {};
  $param = shift;
  
  local $^W;
  if ($param->{ATTRIB} and
      (!$param->{DSN} and !$param->{USER} and !$param->{AUTH})) {
    my $tmp_param = $self->get_param($self->get_dbh());
    $param->{DSN} = $tmp_param->{DSN};
    $param->{USER} = $tmp_param->{USER};
    $param->{AUTH} = $tmp_param->{AUTH};
  }

  my $dbh_key = $self->_dbh_key({DSN => $param->{DSN},
                 USER => $param->{USER},
                 AUTH => $param->{AUTH},
                 ATTRIB => $param->{ATTRIB}});

  $param->{ATTRIB} = $param->{ATTRIB} || {AutoCommit => 1};

  if ($dbh_key) {
    unless (defined $gDBH{$dbh_key}) {
      try {
    $gDBH{$dbh_key} = Enigo::Common::DB::DBI->connect
      ($param->{DSN},
       $param->{USER},
       $param->{AUTH},
       $param->{ATTRIB});
    $gPARAM{$gDBH{$dbh_key}} = $param;
      } catch Enigo::Common::Exception with {
    my $exception = shift;
    my $sql_exception =  Enigo::Common::Exception::SQL::FailedGetDBH->new();
    $sql_exception->attach($exception);
    throw $sql_exception;
      };
    }
    return $gDBH{$dbh_key};
  } else {
    return $gDBH{$self->{DEFAULT_DBH_KEY}};
  }
}


#%% 
#% SUBROUTINE_NAME: get_param
#% AUTHOR: Kirk Haines
#% PURPOSE: returns a hashref containing the connect params for a given DBH.
#% DATE_CREATED: 2000/06/27
#% NOTES:
#% RETURNS: 
#     returns a hashref
#% EXAMPLE: $SQL->get_param($sql->get_dbh());
#
#           $SQL->get_param($dbh2);
#%%


sub get_param {
  my $self = shift;
  my $dbh = shift;

  return $gPARAM{$dbh};
}


#%% 
#% SUBROUTINE_NAME: get_all_params
#% AUTHOR: Kirk Haines
#% PURPOSE: returns a hash containing all of the DBH's as
#  keys and all of their params as values.
#% DATE_CREATED: 2000/06/27
#% NOTES:
#% RETURNS: 
#     returns a list of hashrefs
#% EXAMPLE: @paramlist = $SQL->get_all_params();
#%%


sub get_all_params {
  my $self = shift;

  my %return_hash = (%gPARAM);
  return %return_hash;
}


#%%
#% SUBROUTINE_NAME: set_default_dbh
#% AUTHOR: Kirk Haines
#% PURPOSE: Set the SQL object's default database handle.
#% DATE_CREATED: 06 Jun 2000
#% NOTES: This will throw an exception if there is no handle
#    being held to the database requested with the username and
#    authorization specified. 
#% RETURNS:
#% EXAMPLE: $SQL->set_default_dbh({DSN => 'webdatabase',
#                                  USER => 'skippy',
#                                  AUTH => 'hoppy'});
#%%

sub set_default_dbh {
  my $self = shift;
  my $param = shift;

  my $dbh_key = $self->_dbh_key({DSN => $param->{DSN},
                 USER => $param->{USER},
                 AUTH => $param->{AUTH},
                 ATTRIB => $param->{ATTRIB}});

  throw Enigo::Common::Exception::SQL::InvalidDefaultDBH
    ({USER => $param->{USER},
      DSN => $param->{DSN}})
      unless (defined $gDBH{$dbh_key});

  $self->{DEFAULT_DBH_KEY} = $dbh_key;
}



#%% 
#% SUBROUTINE_NAME: scalar
#% AUTHOR: Jeff Bay
#% PURPOSE: 
#     This sub should be used to get one and only one piece of info from the database.
#     It will die if you attempt to give it a query that returns more than one row or column.
#% DATE_CREATED: 2000/05/24
#% ARGUMENTS:
#@    $sql
#% RETURNS: 
#     a scalar value
#% EXAMPLE: $sql->scalar("select foo from table where foo = 1234");
#% NOTES:  What happens when the scalar has a null value?  Do we return undef? or
#          an empty string?  (should be undef.) 
#%%

sub scalar {
  my $self = shift;
  my $sql = shift;
  my @params = @_;

  my $dbh = $self->get_dbh();
  my $statement;
  try {
    $statement = $dbh->prepare($sql);
    $statement->execute(@params);
  } catch Enigo::Common::Exception::IO::DB with {
    my $exception = shift;
    my $sql_exception =
      Enigo::Common::Exception::SQL::FailedSQLStatement->new($sql);
    $sql_exception->attach($exception);
    throw $sql_exception;
  };

  my $rows_ref = $statement->fetchall_arrayref();
  throw Enigo::Common::Exception::SQL::BadScalarQuery({TYPE=>'row', SQL=> $sql})
    unless defined $rows_ref;

  my $cols_ref = $$rows_ref[0];
  throw Enigo::Common::Exception::SQL::BadScalarQuery({TYPE=>'column', SQL=> $sql})
    unless defined $cols_ref;

  if (scalar @$rows_ref != 1 and scalar @$cols_ref != 1)
    {
      my $row_exception =
    Enigo::Common::Exception::SQL::BadScalarQuery->new({TYPE => 'row',
                                SQL => $sql});
      my $column_exception =
    Enigo::Common::Exception::SQL::BadScalarQuery->new({TYPE => 'column',
                                SQL => $sql});

      $column_exception->attach($row_exception);
      throw $column_exception;
    }

  throw Enigo::Common::Exception::SQL::BadScalarQuery({TYPE => 'row',
                               SQL => $sql})
    unless scalar @$rows_ref == 1;

  throw Enigo::Common::Exception::SQL::BadScalarQuery({TYPE => 'column',
                               SQL => $sql})
    unless scalar @$cols_ref == 1;

  return $cols_ref->[0];
}

#%% 
#% SUBROUTINE_NAME: row
#% AUTHOR: Jeff Bay
#% PURPOSE: 
#     This sub should be used to get one and only one row of info from the database.
#     It will die if you attempt to give it a query that returns more than one row.
#     It returns that row as an array of scalars in column order.
#% DATE_CREATED: 2000/05/24
#% ARGUMENTS:
#@    $sql
#% RETURNS: 
#     a list of column values for one row
#% EXAMPLE: @columns = $sql->row("select foo,bar,baz from table where foo = 1234");
#%%

sub row {
  my $self = shift;
  my $sql = shift;
  my @params = @_;

  my $statement;
  try {
    $statement = $self->get_dbh()->prepare($sql);
    $statement->execute(@params);
  } catch Enigo::Common::Exception::IO::DB with {
    my $exception = shift;
    my $sql_exception =
      Enigo::Common::Exception::SQL::FailedSQLStatement->new($sql);
    $sql_exception->attach($exception);
    throw $sql_exception;
  };

  my $rows_ref = $statement->fetchall_arrayref();

  throw Enigo::Common::Exception::SQL::BadRowQuery({TYPE => 'more',
                            SQL => $sql})
    unless scalar @$rows_ref <= 1;

  my $cols_ref = $$rows_ref[0];

  return $cols_ref ? @{ $cols_ref } : undef;
}

#%% 
#% SUBROUTINE_NAME: hash
#% AUTHOR: Jeff Bay
#% PURPOSE: 
#     This sub should be used to get one and only one row of info from the database.
#     It will die if you attempt to give it a query that returns more than one row.
#     It returns that row as a hash with keys that are column names and values are column values
#% DATE_CREATED: 2000/05/24
#% ARGUMENTS:
#@    $sql
#% RETURNS: 
#     a hash containing COLUMN-NAME => COLUMN VALUE
#% EXAMPLE: %data_about_1234 = $sql->hash("select foo,bar,baz from table where foo = 1234");
#           if ($data_about_1234{'foo'} == 7) { do_something(); }
#%%

sub hash {
  my $self = shift;
  my $sql = shift;
  my @params = @_;

  my $statement;
  try {
    $statement = $self->get_dbh()->prepare($sql);
    $statement->execute(@params);
  } catch Enigo::Common::Exception::IO::DB with {
    my $exception = shift;
    my $sql_exception =
      Enigo::Common::Exception::SQL::FailedSQLStatement->new($sql);
    $sql_exception->attach($exception);
    throw $sql_exception;
  };

  my $hash_ref = $statement->fetchrow_hashref();

  throw Enigo::Common::Exception::SQL::BadRowQuery({TYPE => 'none',
                            SQL => $sql})
    unless defined $hash_ref;

  throw Enigo::Common::Exception::SQL::BadRowQuery({TYPE => 'more',
                            SQL => $sql})
    if $statement->fetchrow_hashref();

  return %{ $hash_ref };
}



#%% 
#% SUBROUTINE_NAME: list
#% AUTHOR: Jeff Bay
#% PURPOSE: 
#     This sub should be used to get a single column from the database.
#     it returns a list of scalars, one per matching row. If the query executed
#     would have matched more than one column, it twill throw an exception.
#% DATE_CREATED: 2000/05/24
#% ARGUMENTS:
#@    $sql
#% RETURNS: 
#     a list of scalars, one per row
#% EXAMPLE: @ids = $sql->("select id from table where id is between 1 and 5");
#           foreach my $id (@ids) { print "Member: $id\n"; }
#%%

sub list {
  my $self = shift;
  my $sql = shift;
  my @params = @_;

  my $statement;
  try {
    $statement = $self->get_dbh()->prepare($sql);
    $statement->execute(@params);
  } catch Enigo::Common::Exception::IO::DB with {
    my $exception = shift;
    my $sql_exception =
      Enigo::Common::Exception::SQL::FailedSQLStatement->new($sql);
    $sql_exception->attach($exception);
    throw $sql_exception;
  };

  my $rows_ref = $statement->fetchall_arrayref();

  my @data;

  foreach my $cols_array_ref (@$rows_ref) {
    throw Enigo::Common::Exception::SQL::BadColumnQuery({TYPE => 'more',
                             SQL => $sql})
      unless scalar @$cols_array_ref == 1;
    push(@data, $$cols_array_ref[0]);
  }

  return @data;
}

#%% 
#% SUBROUTINE_NAME: row_list
#% AUTHOR: Jeff Bay
#% PURPOSE: 
#     This sub should be used to get a list of rows from the database.
#     it returns a list of arrayrefs, one per matching row, where each array-ref is 
#     a reference to the ordered columns for that row.
#% DATE_CREATED: 2000/05/24
#% ARGUMENTS:
#@    $sql
#% RETURNS: 
#     a list of array-refs.
#% EXAMPLE: @people = $sql->("select * from table where id is between 1 and 5");
#           foreach my $people_row (@people) { my $id = shift @$people_row; print "id: $id, Other Data: @$people_row; }
#%%

sub row_list {
  my $self = shift;
  my $sql = shift;
  my @params = @_;

  my $statement;
  try {
    $statement = $self->get_dbh()->prepare($sql);
    $statement->execute(@params);
  } catch Enigo::Common::Exception::IO::DB with {
    my $exception = shift;
    my $sql_exception =
      Enigo::Common::Exception::SQL::FailedSQLStatement->new($sql);
    $sql_exception->attach($exception);
    throw $sql_exception;
  };

  my $rows_ref = $statement->fetchall_arrayref();

  my @rows;

  foreach my $cols_array_ref (@$rows_ref) {
    push(@rows, $cols_array_ref);
  }

  return @rows;
}

#%% 
#% SUBROUTINE_NAME: row_list
#% AUTHOR: Jeff Bay
#% PURPOSE: 
#     This sub should be used to get a list of rows from the database.
#     it returns a list of hashrefs, one per matching row, where each hash-ref is 
#     a reference to a hash containing COLUMN-NAME => COLUMN-VALUE pairs.
#% DATE_CREATED: 2000/05/24
#% ARGUMENTS:
#@    $sql
#% RETURNS: 
#     a list of array-refs.
#% EXAMPLE: @people = $sql->("select * from table where id is between 1 and 5");
#           foreach my $people_row (@people) { my $id = shift @$people_row; print "id: $id, Other Data: @$people_row; }
#%%

sub hash_list {
  my $self = shift;
  my $sql = shift;
  my @params = @_;

  my $statement;
  try {
    $statement = $self->get_dbh()->prepare($sql);
    $statement->execute(@params);
  } catch Enigo::Common::Exception::IO::DB with {
    my $exception = shift;
    my $sql_exception =
      Enigo::Common::Exception::SQL::FailedSQLStatement->new($sql);
    $sql_exception->attach($exception);
    throw $sql_exception;
  };

  my @rows;
  while (my $hash_ref = $statement->fetchrow_hashref()) {
    push(@rows, $hash_ref);
  }

  return @rows;
}


sub insert {
  my $self = shift;
  my $sql = shift;
  my @params = @_;

  my $statement;
  my $rv;
  try {
    $statement = $self->get_dbh()->prepare($sql);
    $rv = $statement->execute(@params);
  } catch Enigo::Common::Exception::IO::DB with {
    my $exception = shift;
    my $sql_exception =
      Enigo::Common::Exception::SQL::FailedSQLStatement->new($sql);
    $sql_exception->attach($exception);
    throw $sql_exception;
  };

  return $rv;
}


sub update {
  my $self = shift;
  my $sql = shift;
  my @params = @_;

  my $statement;
  my $rv;
  try {
    $statement = $self->get_dbh()->prepare($sql);
    $rv = $statement->execute(@params);
  } catch Enigo::Common::Exception::IO::DB with {
    my $exception = shift;
    my $sql_exception =
      Enigo::Common::Exception::SQL::FailedSQLStatement->new($sql);
    $sql_exception->attach($exception);
    throw $sql_exception;
  };

  return $rv;
}


sub delete {
  my $self = shift;
  my $sql = shift;
  my @params = @_;

  my $statement;
  my $rv;
  try {
    $statement = $self->get_dbh()->prepare($sql);
    $rv = $statement->execute(@params);
  } catch Enigo::Common::Exception::IO::DB with {
    my $exception = shift;
    my $sql_exception =
      Enigo::Common::Exception::SQL::FailedSQLStatement->new($sql);
    $sql_exception->attach($exception);
    throw $sql_exception;
  };

  return $rv;
}


sub _dbh_key {
  my $self = shift;
  my $param = shift;

  return undef unless ($param->{DSN} or $param->{USER});

  return join('::',
          $param->{DSN},
          $param->{USER},
          map {"$_\->$param->{ATTRIB}->{$_}"} keys %{$param->{ATTRIB}});
}


1;



