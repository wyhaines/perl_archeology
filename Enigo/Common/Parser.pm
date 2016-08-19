#!/usr/bin/perl -wc
#
######################################################################
##### Header
######################################################################
=pod

=head1 FILE_NAME: $RCSfile: Parser.pm,v $

=head1 Enigo::Common::Parser;

I<REVISION:$Revision: 1.1.1.1 $>

I<AUTHOR: $Author: khaines $>

I<DATE_MODIFIED: $Date: 2001/12/17 02:28:37 $>

=head1 PURPOSE:

Provides an object that can perform evaluation of arbitrarily
complex boolean type statements.  Includes facilities for
querying the values of variables from the database, and for
doing both full evaluations on a statement and "best case"
evaluations.  "Best case" evaluations are used when some
variables in a statement may have an unknown value, and
there is a desire to see if there is any possibility of the
rule evaluating to true given the currently known variables.

=head1 TODO:

There are probably lots of code efficiency issues that could
be resolved.

There is also a lot of documentation that can be improved.
Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################
package Enigo::Common::Parser;

use strict;

use DBI;

use Enigo::Common::Exception qw(:IO);

$Enigo::Common::Parser::VERSION = '1.3.62.1';



######################################################################
##### Constructor: new
######################################################################

=pod

=head2 CONSTRUCTOR_NAME: new

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 12 Jul 2000>

=head2 PURPOSE:

Creates a hash reference blessed into Enigo::Common::Parser.

=head2 ARGUMENTS:



=head2 RETURNS:

=head2 EXAMPLE

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub new {
  my ($type) = shift;
  my ($self) = {};
  my ($hash) = shift || {};
  bless($self,$type);
  $self->{DIMENSION} = $hash;
  $self->{DATA} = {};
  
  return $self;
}



######################################################################
##### Method: setDimension
######################################################################

=pod

=head2 METHOD_NAME: setDimension

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 12 Jul 2000>

=head2 PURPOSE:

Adds a dimension definition to the list of dimensions.

=head2 ARGUMENTS:

Takes two arguments, the name of the dimension and a
true or false value to indicate whether the dimension
should be resolved at parse time or defered.

The arguments can be passed via a hash reference with the
keys of NAME and RESOLVE.

=head2 RETURNS:

=head2 EXAMPLE

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub setDimension {
  my ($self) = shift;
  
  my $name;
  my $resolve;
  if (ref($_[0]) eq 'HASH') {
    $name = $_[0]->{NAME};
    $resolve = $_[0]->{RESOLVE};
  } else {
    $name = $_[0];
    $resolve = $_[1];
  }
  
  $self->{DIMENSION}->{$name} = $resolve;
  return 1;
}



######################################################################
##### Method: delDimension
######################################################################

=pod

=head2 METHOD_NAME: delDimension

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 12 Jul 2000>

=head2 PURPOSE:

Deletes the specified dimension definition from the dimension
hash.

=head2 ARGUMENTS:

A scalar containing the name of the dimension to delete.

=head2 RETURNS:

undef

=head2 EXAMPLE

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub delDimension {
  my ($self) = shift;
  my ($name) = shift;
  
  delete($self->{DIMENSION}->{$name});
  return undef;
}



######################################################################
##### Method: getDimension
######################################################################

=pod

=head2 METHOD_NAME: getDimension

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 12 Jul 2000>

=head2 PURPOSE:

Returns the dimension resolution value for a given dimension or
undef it the dimension is not defined.

=head2 ARGUMENTS:

A scalar containing the name of the dimension to return the
resolution value of.

=head2 RETURNS:

A scalar containing the resolution value of the dimension, or
undef if the dimension is not defined.

=head2 EXAMPLE

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub getDimension {
  my ($self) = shift;
  my ($name) = shift;
  
  return keys(%{$self->{DIMENSION}}) unless (defined($name));
  return $self->{DIMENSION}->{$name} if (defined($self->{DIMENSION}->{$name}));
  return undef;
}



######################################################################
##### Method: clearData
######################################################################

=pod

=head2 METHOD_NAME: clearData

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 12 Jul 2000>

=head2 PURPOSE:

Clears the data hash.

=head2 ARGUMENTS:

none

=head2 RETURNS:

undef;

=head2 EXAMPLE

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub clearData {
  my ($self) = shift;
  
  $self->{DATA} = {};
  return undef;
}



######################################################################
##### Method: setData
######################################################################

=pod

=head2 METHOD_NAME: setData

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 12 Jul 2000>

=head2 PURPOSE:

Sets a name.value pair in the hash of data to use in the expression
to be parsed.

=head2 ARGUMENTS:

Takes two scalar arguments, the name of the field to set, and the
value to set in that field.  These arguments can also be passed
via a hash references with keys of NAME and VALUE.

=head2 RETURNS:

undef;

=head2 EXAMPLE

=head2 TODO:

The argument handling needs to be brought in line with the arguments
description above.

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub setUserData {
  my ($self) = shift;
  my ($name) = shift;
  my ($value) = shift;

  if (ref($name) eq 'HASH') {
    $self->{DATA} = $name;
  } else {
    $self->{DATA}->{$name} = $value;
  }

  return undef;
}


######################################################################
##### Method: getUserData
######################################################################

=pod

=head2 METHOD_NAME: getUserData

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 12 Jul 2000>

=head2 PURPOSE:

Access userdata items.

=head2 ARGUMENTS:

Takes as a parameter the name of the 'userdata' field to return.
If no name is given returns a reference to a hash containing all
of the field/value pairs.

=head2 RETURNS:

A scalar containing a userdata element, or a hash reference that
contains all of the userdata field/value pairs.

=head2 EXAMPLE

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub getUserData {
  my ($self) = shift;
  my ($name) = shift;
  
  if ($name) {
    return $self->{DATA}->{$name};
  } else {
    my ($val) = {};
    my ($t);
    
    foreach $t (keys(%{$self->{DATA}})) {
      $val->{$t} = $self->{DATA}->{$t};
    }
    return $val;
  }
}



######################################################################
##### Method: setDBH
######################################################################

=pod

=head2 METHOD_NAME: setDBH

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 12 Jul 2000>

=head2 PURPOSE:

Sets the DBH that the object should use for looking up data items
within the database.

=head2 ARGUMENTS:

Takes a single argument containing a database handle and sets
$self->{'dbh'} to it;

=head2 RETURNS:

undef;

=head2 EXAMPLE

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub setDBH {
  my ($self) = shift;
  my ($dbh) = shift;
  
  $self->{DBH} = $dbh;
  return undef;
}



######################################################################
##### Method: parse
######################################################################

=pod

=head2 METHOD_NAME: parse

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 12 Jul 2000>

=head2 PURPOSE:

Parses a boolean statement and reduces it down to the simplest
form possible.  If values for all of the elements in the
statement are known, the statement will be solved.  Otherwise,
the statement will be reduced to the simplest form possible
without actually having enough information to solve it.

=head2 ARGUMENTS:

Takes the line to parse as an argument.  Returns a parsed version
of that line.  A weight for the rule may also be passed as the
second argument.  If not provided, weight defaults to 10.

Also, optionally takes a reference to a hash containing field/value
data pairs.  If this hash reference is passed, $self->{'userdata'}
is set to it.  A fourth optional argument is the database handle
to use.  $self->{'dbh'} will be set to it.

A fifth argument indicates whether to do a normal evaluation or a
best case evaluation for unknown dimensions.  A negative number
indicates best case. Any other number indicates a normal evaluation.

Arguments may also be passed via a hash.  Element keys are RAW,
WEIGHT, DATA, DBH, and SIGN, respectively.

=head2 RETURNS:

A parsed version of the line.

=head2 EXAMPLE

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub parse {
  my ($self) = shift;
  
  my ($raw) = shift;
  my ($weight);
  my ($data);
  my ($dbh);
  my ($sign);
  
  if (ref($raw) eq 'HASH') {
    my ($h) = $raw;
    $raw = $h->{RAW};
    $weight = $h->{WEIGHT};
    $data = $h->{DATA};
    $dbh = $h->{DBH};
    $sign = $h->{SIGN};
  } else {
    $weight = shift;
    $data = shift;
    $dbh = shift;
    $sign = shift;
  }
  
  if ($sign < 0) {
    $sign = -1;
  } else {
    $sign = 1;
  }
  
  $weight = 10 unless ($weight);
  $self->{DATA} = $data if ($data);
  $self->{DBH} = $dbh if ($dbh);
  $self->{WEIGHT} = [];
  
  push(@{$self->{WEIGHT}},$weight);
  
  return $self->_parse($raw,$sign);
}



######################################################################
##### Method: _parse
######################################################################

=pod

=head2 METHOD_NAME: _parse

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 12 Jul 2000>

=head2 PURPOSE:

This is the private method that actually parses the rule.  It
recursively descends through the text of the rule, evaluating
the comparisons and replacing rule labels with the corresponding
text from the rule itself.

=head2 ARGUMENTS:

It takes one mandatory argument, the text to parse.

It also takes one optional argument, the sign of the last operator
to be parsed.  That is, '1' unless the last operator was a '!', in
which case it is a '-1'.  This allows for proper worst-case
evaluation of dynamic dimensions.  If this is not done, a logical
negation of a comparison of a dynamic dimension could result in
evaluating a rule as true for a user where that can not be
adequately determined without knowing the value of the dynamic.

A third argument, if provided, indicates whether to do a normal
evaluation or a best case evaluation for unknown dimensions.  If 0
or a positive number, a normal evaluation is done.  If negative,
a best case evaluation is done.

=head2 RETURNS:

=head2 EXAMPLE

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

#####
# _parse
#####
sub _parse {
  my ($self) = shift;
  my ($raw) = shift;
  my ($sign) = shift;

  my ($car,$cdr,$evl,$result);

  return unless ($raw);

  while (length($raw) > 0) {
    if ($raw =~ /^\s*((?:\w+\s*(?:=|>|<|!=|>=|<=|=~|!~)\s*(?:\w+|[\d\.]+|\"(?:[^\"\\]+|\\.)*\")))\s*(.*)$/o) {
      #If $raw starts with a 'WORD cmp VAL' or 'WORD cmp "VAL"' where WORD is
      #assumed to be the name of a dimension, cmp is a comparison operator,
      #and VAL is an unquoted numeric value or any quoted value.

      $cdr = $2;

      $1 =~ /^(\w+)\s*(=|>|<|!=|>=|<=|=~|!~)\s*(\w+|[\d\.]+|\"(?:[^\"\\]+|\\.)*\")/o;
      #Break the expression into it's constituent parts.
      my ($dim) = $1;
      my ($cpr) = $2;
      my ($val) = $3;
      $val =~ s/^\"(.*)$/$1/;
      $val =~ s/^(.*)\"$/$1/;

      if ($self->{DIMENSION}->{$dim} == 1 or
      ($self->{DIMENSION}->{$dim} == 1 and
       $self->{DIMENSION}->{$val} == 1)) {
    #If the dimension being referenced is in the dimension hash and is
    #set to '1', it should be evaluated at this time.

    my ($dimval) = $self->{DATA}->{$dim};
    my ($valval) = $self->{DIMENSION}->{$val} ? $self->{DATA}->{$val} : $val;
    if ($dimval !~ /^[\d\.]+$/o or
        $valval !~ /^[\d\.]+$/o) {
      #Make sure comparison operator is of the appropriate type for
      #the values being compared.

      $dimval =~ s/\"/\\\"/og;
      $dimval = "\"$dimval\"";
      $valval =~ s/\"/\\\"/og;
      $valval = "\"$valval\"";
      if ($cpr eq '=') {
        #           $cpr = 'eq';
      } elsif ($cpr eq '<') {
        $cpr = 'lt';
      } elsif ($cpr eq '>') {
        $cpr = 'gt';
      } elsif ($cpr eq '!=') {
        #   $cpr = 'ne';
      } elsif ($cpr eq '<=') {
        $cpr = 'le';
      } elsif ($cpr eq '>=') {
        $cpr = "ge";
      }
    }
    if ($cpr eq '=') {
      $cpr = '==';
    } elsif (($cpr eq '=~') or ($cpr eq '!~')) {
      $valval =~ s/^\"(.*)$/$1/o;
      $valval =~ s/^(.*)\"$/$1/o;
      $valval = "/$valval/s";
    }
    eval("\$evl = ($dimval $cpr $valval);");
    $evl = 0 unless ($evl);
      } elsif ($self->{DIMENSION}->{$dim} eq '0' or
           $self->{DIMENSION}->{$val} eq '0') {
    #Defer evaluation to a later time if the dimension is known but
    #carries a '0'.  This likely means that this is a dynamic dimension
    $evl = "$dim $cpr $val";
      } else {
    #The dimension is not a known one.  Replace the comparison with a
    #false value.  If the last operator was a logical negation, this
    #results in a 1, else the evaluation returns a 0.  This is used to
    #do a worst-case evaluation of rules which contain comparisons with
    #dynamic values in order determine if a simple true value can be
    #passed to the ad_queue for this user/ad pair or if the actual rule
    #will need to be passed.  This is also used, in conjunction with
    #negation from the $sign variable, to do a best case evaluation.
    #If the rule evaluates to false even under a best-case evaluation,
    #then there is no possible user/ad match.
    if ($sign == 1) {
      $evl = 0;
    } else {
      $evl = 1;
    }
      }
    } elsif ($raw =~ /^\s*(AND|OR|and|or|NOT|not|!)\s*(.*)$/o) {
      $cdr = $2;
      $evl = " " . lc($1) . " ";
    } elsif ($raw =~ /^\s*(0|1|TRUE|FALSE|true|false)\s*(.*)$/o) {
      $cdr = $2;
      if (lc($1) eq 'true') {
    $evl = 1;
      } elsif (lc($1) eq 'false') {
    $evl = 0;
      } else {
    $evl = $1;
      }
    } elsif ($raw =~ /^\s*(\w+|\"(?:[^\"\\]+|\\.)*\")\s*(.*)$/o and $self->{dbh}) {
      $car = $1;
      $cdr = $2;

      $car = "\"$car\"" if ($car =~ /^\w+$/o);
      my ($sql) = "select weight,rule from rule where label = $car";
      my ($sth) = $self->{'dbh'}->prepare($sql);
      $sth->execute();
      my (@data);
      @data = $sth->fetchrow_array;
      push(@{$self->{'weight'}},$data[0]);
      $evl = $data[1];
    } elsif ($raw =~ /^\s*([\(\)])\s*(.*)$/o) {
      $cdr = $2;
      $evl = $1;
    } else {
      $raw =~ /^(.)(.*)$/o;
      $cdr = $2;
      $evl = $1;
    }
    $raw = $cdr;
    $result .= $evl;
  }
  return $result;
}

1;

