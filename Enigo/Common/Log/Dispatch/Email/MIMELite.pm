package Enigo::Common::Log::Dispatch::Email::MIMELite;

use strict;
use vars qw(@ISA $VERSION);

use base qw(Enigo::Common::Log::Dispatch::Email);
require Log::Dispatch::Email::MIMELite;
push @ISA,'Log::Dispatch::Email::MIMELite';

sub send_email
{
    my Enigo::Common::Log::Dispatch::Email::MIMELite $self = shift;

    $self->Log::Dispatch::Email::MIMELite::send_email(@_);
}

1;

