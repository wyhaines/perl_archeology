package Enigo::Common::Log::Dispatch::Email::MailSend;

use strict;
use vars qw(@ISA $VERSION);

use base qw(Enigo::Common::Log::Dispatch::Email);
require Log::Dispatch::Email::MailSend;
push @ISA,'Log::Dispatch::Email::MailSend';

use Mail::Send;

sub send_email
{
    my Enigo::Common::Log::Dispatch::Email::MailSend $self = shift;

    $self->Log::Dispatch::Email::MailSend::send_email(@_);
}

1;
