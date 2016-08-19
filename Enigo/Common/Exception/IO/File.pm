#!/usr/bin/perl -c
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: $RCSfile: File.pm,v $

=head1 Enigo::Common::Exception::IO::File

I<REVISION:$Revision: 1.1.1.1 $>

I<AUTHOR: $Author: khaines $>

I<DATE_MODIFIED: $Date: 2001/12/17 02:28:37 $>

=head1 PURPOSE:

This class represents some sort of general file or filesystem error and
should only be thrown if a more specific subclass does not exist.

=head1 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################
package Enigo::Common::Exception::IO::File;

use strict;

require Enigo::Common::Exception::IO;

@Enigo::Common::Exception::IO::File::ISA =
  qw(Enigo::Common::Exception::IO);
$Enigo::Common::Exception::IO::File::VERSION = '2000_06_16_07_35';


######################################################################
##### Constructor: new
######################################################################

=pod

=head2 CONSTRUCTOR_NAME: new

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 16 JUN 2000>

=head2 PURPOSE:

To return an Enigo::Common::Exception::IO::File exception.

=head2 ARGUMENTS:

Takes either one (or two) scalar arguments, the FILE of the error and,
optionally, the VALUE of the exception, or takes a hashref with FILE
and, optionally, VALUE, as parameters.  Value defaults to 1 if not
provided.

FILE is the filesystem path on which there is a problem.

=head2 RETURNS:

An hash blessed into Enigo::Common::Exception::IO::File.

=head2 EXAMPLE:

  throw Enigo::Common::Exception::IO::File
    ('/var/log/mylog.log');

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub new
  {
    my ($self) = shift;

    my $param = {FILE => '',
         VALUE => 1};

    if (ref($_[0]) eq 'HASH')
      {
    $param->{FILE} = $_[0]->{FILE};
        $param->{VALUE} = exists $_[0]->{VALUE} ? $_[0]->{VALUE} :
                                                  $param->{VALUE};
      }
    else
      {
    $param->{FILE} = $_[0];
        $param->{VALUE} = defined $_[1] ? $_[1] :  $param->{VALUE};
      }

    my @args;

    return(bless Enigo::Common::Exception->new
       ({TEXT => "Error: FileError: There was an error with $param->{FILE}\n<ERROR_LOCATION/>",
         VALUE => $param->{VALUE}}),
       $self);
  }


1;
