package Enigo::Common::Log::Dispatch::Email::MailSendmail;

use strict;
use vars qw(@ISA $VERSION);

use base qw(Enigo::Common::Log::Dispatch::Email);
require Log::Dispatch::Email::MailSendmail;
push @ISA,'Log::Dispatch::Email::MailSendmail';

sub send_email
{
    my Enigo::Common::Log::Dispatch::Email::MailSendmail $self = shift;

    $self->Log::Dispatch::Email::MailSendmail::send_email(@_);
}

1;
