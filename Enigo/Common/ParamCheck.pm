#!/usr/bin/perl -wc
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: ParamCheck.pm

=head1 Enigo::Common::ParamCheck

I<REVISION: $Revision: 1.1.1.1 $>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: $Date: 2001/12/17 02:28:37 $>

=head1 PURPOSE:

Provides a standard routine to:

A) Check the parameters to make sure they are of the
expected types.

B) Allow for sophisticated parameter handling.  No need for writing
extensive, non-resuable code in the calling routine.

C) Return the parameters in a consistent form for use in the code
of the calling routine.

=head1 EXAMPLE:

  use ParamCheck qw(paramCheck);
  my ($param) = paramCheck([BLOCKING => 'U'],@_);

=head1 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

package Enigo::Common::ParamCheck;

use strict;

use DBI;

use Data::Dumper;

use Enigo::Common::Exception qw(:IO);
require Enigo::Common::Exception::ParamCheck::NoParameterList;
require Enigo::Common::Exception::ParamCheck::BadParameterListSyntax;
require Enigo::Common::Exception::ParamCheck::UnknownHashParam;
require Enigo::Common::Exception::ParamCheck::InvalidParam;
require Enigo::Common::Exception::ParamCheck::MissingParam;

use Exporter;
@Enigo::Common::ParamCheck::ISA = qw(Exporter);
$Enigo::Common::ParamCheck::VERSION = '1.1.2.4';
@Enigo::Common::ParamCheck::EXPORT_OK = qw(&paramCheck);



######################################################################
##### Method: paramCheck
######################################################################

=pod

=head2 METHOD_NAME: paramCheck

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 15 Jun 2000>

=head2 PURPOSE:

paramCheck() provides a facility for checking the arguments passed
into a method/function.  It expects to receive as its first
argument an array reference containing the list of expected or
acceptable parameters (the format for this list is explained
below), followed by the list of parameters to check, and any
default values to be used for any of the parameters.

The routine can deal with parameters passed either via a hash
reference, such as in the following example:

  $object->method({PARAM1 => 'foo',
           PARAM2 => 'mitzy',
           PARAM3 => \*frob});


It can also deal with parameters passed via array, as in:

  $object->method('foo','mitzy',\*frob);

If called in a scalar context, it returns a hash reference
containing all of the parsed parameters, and if called in an
array context, returns an array where the first element is
a hash reference containing all of the parsed parameters, and
any following values are unmatched parameters left over from
the parameter list that was passed into the routine.

If an error occurs while parsing the parameters, an exception
will be thrown.  Possible errors include a malformed call to
paramCheck (such as having an error in the list of expected
parameters), and having an error with the paremeter list
such as a parameter which is not of the correct type, or
a missing parameters.

=head2 ARGUMENTS:

paramCheck() expects that its first argument is an array reference
containing the information on all of the possible parameters.

The data in this array reference is a set of key/value pairs.
The order of these pairs is important, as if paramCheck is checking
an array of parameters, instead of a hash ref of parameters,
the order in which the expected parameters are specified is the
order in which they are expected.

The key in each of these pairs is the name of the parameter.
This is the key that would be used if parameter values were
being passed via a hash ref, and is the key that the parameter
value will be associated with in the hash ref that paramCheck()
returns to its caller.

The value in each pair is either a simple scalar value that
indicates the type of the expected parameter, or an array
reference with the first value being the type, and the second
value being the default for this parameter.  Thus:
  
  my $param = paramCheck([FLIPPER => 'CD=/^(?:l|r)$/i',
                          SPECIES => ['A','dolphin']],@_);
  
means that the type for the first parameter, FLIPPER, is
'CD=/^(?:l|r)$/i', while SPECIES has a type of 'A' and a
default value of 'dolphin'.

Parameters are assumed to be mandatory unless the type code
is suffixed with an 'O', which indicates that the parameter is
optional.  Thus:
  
  my $param = paramCheck([AGE => 'N',
                          GENDER => 'CDO=/^(?:m|f)$/i'],@_);
  
would require that the AGE parameter be provided, but would allow
the GENDER parameter to be omitted.

The full list of types is:

=over 4

=item CD

Perl code which will be evaluated, passing to it the current key
(scalar), the value for that key (scalar), and the remainder of
unparsed parameters (array ref).

  @_ = ($key,$value,$remainder);

In addition, $_ is set to the current parameter value.

This allows the code to know what parameter it is checking, and
because the list of remaining parameters to check is passed in
via @_, it also allows the code to alter this list as a side
effect.  This can be a useful feature, but it may also be a
bad thing.  However, a little danger here and there can be
fun.

If the code evaluates to true, then the parameter is deemed
valid.  If it evaluates to false, the parameter is deemed
invalid, and an exception will be thrown.

This type can thus be used to code for complex checks that
are not covered by any of the other types described below.
One of the best uses of it is to apply a regex to the
parameter.

=item ECR

This is similar to CD, except that the value of the parameter
in this case is expected to be an executable code reference.

That code reference will be called, passing into it the
parameter key and the remainder of unparsed parameters, like
this:
  
  $result = &{$value}($key,$remainder);
  
If the code executes successfully, then the value that paramCheck
assigns to this parameter will be the return value from the code.

If the code die()s, then the parameter is deemed invalid and an
exception is thrown.

=item CR

This type demands that the parameter value be a code ref.  If the
parameter is of any other type, an exception will be thrown.

=item GR

This type demands that the parameter value be a reference to a
glob.  If the parameter is of any other type, an exception will
be thrown.

=item HR

The parameter must be a hash reference, or an exception will be
thrown.

=item AR

The parameter must be an array reference, or an exception will
be thrown.

=item SR

A scalar reference is expected for the parameter.  An exception
is thrown if it is not received.

=item AN

An alphanumeric data item is expected.  This means any letters,
numbers, or the underscore character are acceptable.  In addition,
whitespace characters can occur in the parameter.

=item A

This data type requires that the parameter be composed only of
alphabetic characters.

=item RR

This quirky little type means that a reference to a reference
is expected.  What fun!

=item UR

UR is Unrestricted Reference.  Meaning that any type of reference
will be accepted.  As with all other data types, if the wrong
type of data is received (non-reference data), an exception
will be thrown.

=item I

This indicates that an integer value is expected.

=item N

N says that any numeric value is acceptable.

=item U

U is Unrestricted.  Anything at all is an acceptable parameter
value.

=back

As was mentioned earlier, suffixing any of the above type codes
with an 'O' indicates to paramCheck that the parameter that
is being described is an optional parameter.

Because of the ambiguities that can result from the combination
of optional parameters and param values passed via an array,
paramCheck does not support the use of optional parameters
when processing a set of param values that have been passed
via an array.  It _can_ work, but it is a tricky thing,
so if you want to employ optional parameters, do yourself
a favor and pass the params via a hash reference.  It is a little
bit more verbose that passing via an array, but it is also
more efficient from a Perl internals level, especially if there
are a lot of parameters, and it makes for clearer, more
self-documenting code, too.

=head2 THROWS:

  Enigo::Common::Exception::ParamCheck::NoParameterList
  Enigo::Common::Exception::ParamCheck::BadParameterListSyntax
  Enigo::Common::Exception::ParamCheck::MissingParam

=head2 RETURNS:

When called in a scalar context, returns a hash ref containing
all of the parsed params.  When called in an array context,
returns the above mentioned hash reference as the first element
in the array, and all of the unparsed elements remaining in the
original parameter list in all of the following elements.

=head2 EXAMPLE:

  my $param = paramCheck([PARAM => 'A'],@_);
  my ($param,@remainder) = paramCheck([ARG => 'HR',
                                       DEFAULT => ['A','stuff'],
                                       OPTION => 'IO'],@_);

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################
sub paramCheck {
  \@_;
  #The first argument is the parameter definitions, in a hash ref.
  my $tmp_param_list = shift;
  
  local $Error::Depth = $Error::Depth + 2;
  throw Enigo::Common::Exception::ParamCheck::NoParameterList()
    unless ref($tmp_param_list) eq 'ARRAY';
  throw Enigo::Common::Exception::ParamCheck::BadParameterListSyntax()
    unless (_parameter_type_list_syntax_okay(@{$tmp_param_list}));
  
  #parameter_type_list is a psuedohash that associates parameter
  #key names with their values.
  $Enigo::Common::ParamCheck::parameter_type_list = [{}];    
  my $index_hash = {};
  my $index_count = 0;
  while (scalar(@{$tmp_param_list})) {
    my $key = shift @{$tmp_param_list};
    my $data = shift @{$tmp_param_list};
    my $type;
    my $default = undef;
    if (ref($data) eq 'ARRAY') {
      $type = $data->[0];
      $default = $data->[1];
      
      my $first_hash;
      my $found_key_in_params = 0;
      foreach my $item (@_) {
    next unless ref($item) eq 'HASH';
    $first_hash = $item unless ($first_hash);
    
    foreach my $item_key (keys(%{$item})) {
      $found_key_in_params++ if $item_key eq $key;
    }
    last if $found_key_in_params;
      }
      $first_hash->{$key} = $default unless ($found_key_in_params);     
    } else {
      $type = $data;
    }
    
    $index_count++;
    $index_hash->{$key} = $index_count;
    push(@{$Enigo::Common::ParamCheck::parameter_type_list},
     {KEY => $key,
      TYPE => $type,
      DEFAULT => $default});
  }
  $Enigo::Common::ParamCheck::parameter_type_list->[0] = $index_hash;
  $Enigo::Common::ParamCheck::parsed_params = {};
 
  _paramcheck(\@_);

  if (keys(%{$Enigo::Common::ParamCheck::parameter_type_list})) {
    my $raise_error = 0;
    my $count = 0;
    while ($count < (scalar(@{$Enigo::Common::ParamCheck::parameter_type_list})) -1 ) {
      $count++;
      my $key = $Enigo::Common::ParamCheck::parameter_type_list->[$count]->{KEY};
      my $type = $Enigo::Common::ParamCheck::parameter_type_list->[$count]->{TYPE};
      my $default =
    $Enigo::Common::ParamCheck::parameter_type_list->[$count]->{DEFAULT};
      if ($default !~ /^$/) {
    $Enigo::Common::ParamCheck::parsed_params->{$key} = $default;
      } elsif ($type =~ /^\w+O/) {
    next;
      } else {
    throw Enigo::Common::Exception::ParamCheck::MissingParam
      ({KEY => $key,
        TYPE => $type});
      }
    }
  }
  
  return wantarray ?
    ($Enigo::Common::ParamCheck::parsed_params,@_) :
      $Enigo::Common::ParamCheck::parsed_params;
}



######################################################################
##### Method: _paramcheck
######################################################################

=pod

=head2 METHOD_NAME: _paramcheck

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 15 Jun 2000

=head2 PURPOSE:

This is a private method that implements the core of the parameter
parsing system.  It will never be called directly.

=head2 ARGUMENTS:

Takes an array reference to an array containing the parameters
to be parsed.

=head2 THROWS:

  Enigo::Common::Exception::ParamCheck::UnknownHashParam
  Enigo::Common::Exception::ParamCheck::InvalidParam

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
sub _paramcheck {
  #Check for recursion end cases.
  #No more params in @_;
  #return unless (scalar(@{$_[0]}) > 0);
  #or no more defined expected params.
  return unless (scalar(keys(%{$Enigo::Common::ParamCheck::parameter_type_list})));

  my $param = shift @{$_[0]};

  if  ((ref($param) eq 'HASH' and
    $Enigo::Common::ParamCheck::parameter_type_list->[1]->{TYPE} !~ /^HR/i) or
       (ref($param) eq 'HASH' and
    $Enigo::Common::ParamCheck::parameter_type_list->[1]->{TYPE} =~ /^HR/i and
    ref($param->{$Enigo::Common::ParamCheck::parameter_type_list->[1]->{KEY}})
    eq 'HASH')) {
    foreach my $key (keys(%{$param})) {
      #It's an error if a key in the parameter hash is different
      #from any of the keys that were given in the parameter
      #definition.
      eval {
    $Enigo::Common::ParamCheck::parameter_type_list->{$key};
      };
      throw Enigo::Common::Exception::ParamCheck::UnknownHashParam($key)
    if ($@);

      #Check to make sure that the parameter value fits with the
      #expected type.
      my $optional;
      throw Enigo::Common::Exception::ParamCheck::InvalidParam
    ({KEY => $key,
      PARAM_VALUE => $param->{$key},
      TYPE => $Enigo::Common::ParamCheck::parameter_type_list->{$key}->{TYPE}})
      unless ((($optional,$param->{$key}) =
           _check_validity($key,$param->{$key},$_[0]))[0]);

      throw Enigo::Common::Exception::ParamCheck::InvalidParam
    ({KEY => $key,
      PARAM_VALUE => $param->{$key},
      TYPE => $Enigo::Common::ParamCheck::parameter_type_list->{$key}->{TYPE}})
      if ($optional == -1); #bad optional param.

      $Enigo::Common::ParamCheck::parsed_params->{$key} = $param->{$key};


      #Remove the parameter from the list.  Thus, the
      #parameter_type_list is a list of all unfulfilled params.
      #This essentially requires rebuilding the list since the
      #indexes for the values of some of the keys will be
      #changing.
      _rebuild_parameter_type_list($key);
    }
  } else {  
    my $optional;
    my $param_copy = $param;
    my $key = $Enigo::Common::ParamCheck::parameter_type_list->[1]->{KEY};
    throw Enigo::Common::Exception::ParamCheck::InvalidParam
      ({KEY => $key,
    PARAM_VALUE => $param,
    TYPE => $Enigo::Common::ParamCheck::parameter_type_list->{$key}->{TYPE}})
    unless ((($optional,$param) = _check_validity($key,$param,$_[0]))[0]);

    if ($optional == -1) {
      unshift(@{$_[0]},$param_copy);
    } else {
      $Enigo::Common::ParamCheck::parsed_params->{$key} = $param;
    }
    _rebuild_parameter_type_list($key);
  }

  _paramcheck(@_);

  return undef;
}
    


######################################################################
##### Method: _rebuild_parameter_type_list
######################################################################

=pod

=head2 METHOD_NAME: _rebuild_parameter_type_list

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 15 June 2000>

=head2 PURPOSE:

Rebuilds the parameter_type_list excluding a single key/value pair.

=head2 ARGUMENTS:

Takes a single scalar value containing the key of the parameter to
exclude from the rebuilt list.

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
    #Rebuilds the parameter_type_list minus one key/value pair.
sub _rebuild_parameter_type_list {
  my $key_to_exclude = shift;

  my $tmp_param_list = $Enigo::Common::ParamCheck::parameter_type_list;
  $Enigo::Common::ParamCheck::parameter_type_list = [{}];
  my $index_hash = {};
  my $index_count = 0;
  foreach my $index (@{$tmp_param_list}[1..$#{$tmp_param_list}]) {
    my $key = $index->{KEY};
    next if $key eq $key_to_exclude;

    $index_count++;
    $index_hash->{$key} = $index_count;
    push(@{$Enigo::Common::ParamCheck::parameter_type_list},
     {KEY => $key,
      TYPE => $index->{TYPE},
      DEFAULT => $index->{DEFAULT}});
  }
  $Enigo::Common::ParamCheck::parameter_type_list->[0] = $index_hash; 

  return undef;
}



######################################################################
##### Method: _parameter_type_list_syntax_okay
######################################################################

=pod

=head2 METHOD_NAME: _parameter_type_list_syntax_okay

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 15 June 2000>

=head2 PURPOSE:

Iterates through the parameter type list to verify that the
syntax of the list is correct.  This will never be called from
outside of this package.

=head2 ARGUMENTS:

The parameter type list as an array.

=head2 THROWS:

nothing

=head2 RETURNS:

Returns false if the syntax is bad, or true if the syntax is correct.

=head2 EXAMPLE:

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################
sub _parameter_type_list_syntax_okay {
  while (scalar(@_)) {
    my $key = shift @_;
    my $data = shift @_;
    my $type;
    if (ref($data) eq 'ARRAY') {
      $type = $data->[0];
    } else {
      $type = $data;
    }
    #Simple requirement:  A parameter key must have a word character in
    #it, someplace.
    return undef if $key !~ /\w/;
    
    #Next, make sure that the param type is one of the defined types
    return undef unless grep {$type =~ /^$_/}
      qw(ECR(?:O)?$ CR(?:O)?$ GR(?:O)?$ HR(?:O)?$ AR(?:O)?$ SR(?:O)?$
     AN(?:O)?$ UR(?:O)?$ RR(?:O)?$ U(?:O)?$ A(?:O)?$ I(?:O)?$
     N(?:O)?$ CD(?:O)?\s*=\s*);
  }
  
  #All of the checks were passed.  The type list looks okay.
  return 1;
}



######################################################################
##### Method: _check_validity
######################################################################

=pod

=head2 METHOD_NAME: _check_validity

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 15 Jun 2000>

=head2 PURPOSE:

Performs the actual parameter validation.  This will not be called
outside of the package.

=head2 ARGUMENTS:

Takes three scalar arguments, the key of the parameter, the value of
the parameter, and the remainder of the parameter list.

=head2 THROWS:

nothing

=head2 RETURNS:

Returns true is the parameter value is valid, or false if the parameter
value is not of the expected type.

=head2 EXAMPLE:

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################
sub _check_validity {
  my $key = shift;
  my $value = shift;
  my $type = $Enigo::Common::ParamCheck::parameter_type_list->{$key}->{TYPE};
  my $default = $Enigo::Common::ParamCheck::parameter_type_list->{$key}->{DEFAULT};
  my $remainder = shift;

  #If there is no value, set the value to the defined default, if there is one.
  $value = $default if (($value =~ /^$/) and ($default !~ /^$/));

  my $optional = 1 if ($type =~ /O$/);
  #No value for an optional argument is okay.
  return (1,$value) if ($optional and $value =~ /^$/);

  {
    #CD: Code -- Code to evaluate, passing it the current key, the current value,
    #and the remainder of @_ (which is passed by reference into _check_validity()
    #and then by reference into the code, meaning that the code can alter it as
    #a side effect...).  The environment for the code is also setup so that $_
    #contains the value.  The return value of the code indicates the validity of the
    #param (true/false).  Single nicest use for this is to use a regex to
    #evaluate a param:
    #
    #  [param => 'CD=/(?:car|truck)/i']
    #
    #  'car' or 'truck', in any case, are the only two permissible values for the
    #  param.
    $type =~ /^CD(?:O)?\s*=\s*(.*)$/ && do {
      #wierd thing.  If I use 'local' on @_ and $_, things get really screwed
      #up, unless the code is running in the debugger.  So, I guess I don't
      #use local on those two variables, eh?
      my $cr = $1;
      unless (defined $Enigo::Common::ParamCheck::CD_CODE{q($cr)}) {
    my $code = <<ECODE;
\$Enigo::Common::ParamCheck::CD_CODE{q($cr)} = sub {
  local \$_ = \$_[1];
  $cr
};
ECODE
        eval $code;
      }
no strict 'refs';
      my $result = &{$Enigo::Common::ParamCheck::CD_CODE{$cr}}($key,$value,$remainder);
use strict 'refs';
      return $result ? (1,$value) :
    $optional ? (-1,undef) : undef;
    };
    #ECR: Executable Code Ref -- A code ref that is to be called, passing
    #it the current key and the remainder of @_ (which is passed by reference
    #into _check_validity() and then by reference into the code ref, meaning
    #that the code ref can alter it as a side effect...).  The return value of the
    #code ref is the value of the param.  If the param is invalid, the code being
    #executed must die() to invalidate the param.
    $type =~ /^ECR/ && do {
      my $result;
      eval {
    $result = &{$value}($key,$remainder);
      };
      return $optional ? (-1,undef) : undef if ($@);
      return (1,$result);
    };

    #CR: Code Ref -- The value must be a code ref.
    $type =~ /^CR/ && do {
      return (ref($value) eq 'CODE') ? (1,$value) :
    $optional ? (-1,undef) : undef;
    };

    #GR: Glob Ref -- A reference to a glob.
    $type =~ /^GR/ && do {
      return (ref($value) eq 'GLOB') ? (1,$value) : $optional ?
    (-1,undef) : undef;
    };

    #HR: Hash Ref -- A reference to a hash.
    $type =~ /^HR/ && do {
      return (ref($value) eq 'HASH') ? (1,$value) : $optional ?
    (-1,undef) : undef;
    };

    #AR: Array Ref -- A reference to an array.
    $type =~ /^AR/ && do {
      return (ref($value) eq 'ARRAY') ? (1,$value) : $optional ?
    (-1,undef) : undef;
    };

    #SR: Scalar Ref -- A reference to a scalar.
    $type =~ /^SR/ && do {
      return (ref($value) eq 'SCALAR') ? (1,$value) : $optional ?
    (-1,undef) : undef;
    };

    #AN: AlphaNumeric -- A scalar containing only alphanumeric characters
    #                    or whitespace.
    $type =~ /^AN/ && do {
      return ($value =~ /^(?:\w|\s)*$/s) ? (1,$value) : $optional ?
    (-1,undef) : undef;
    };

    #UR: Unrestricted Ref -- Any type of reference.
    $type =~ /^UR/ && do {
      return (ref($value)) ? (1,$value) : $optional ?
    (-1,undef) : undef;
    };

    #RR: Ref Ref -- A reference to a reference.
    $type =~ /^RR/ && do {
      return (ref($value) eq 'REF') ? (1,$value) :
    $optional ? (-1,undef) : undef;
    };

    #U: Unrestricted -- a scalar with any content.
    $type =~ /^U/ && do {
      return (1,$value);
    };

    #A: Alpha -- a scalar with only alphabetic content or whitespace.
    $type =~ /^A/ && do {
      return ($value =~ /^(?:[a-zA-Z]|\s)*$/s) ? (1,$value) :
    $optional ? (-1,undef) : undef;
    };

    #I: Integer -- a scalar with an integer value.
    $type =~ /^I/ && do {
      return (int($value) eq $value) ? (1,$value) :
    $optional ? (-1,undef) : undef;
    };

    #N: Numeric -- any numeric value.
    $type =~ /^N/ && do {
      return (($value * 1) eq $value) ? (1,$value) :
    $optional ? (-1,undef) : undef;
    };

  }

  #If the execution path has reached this point, (and it never should),
  #then we've run out of options, and the param is declared to be
  #invalid.
  return undef;
}

1;
