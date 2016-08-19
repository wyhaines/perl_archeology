#!perl
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: mail.pm

=head1

I<REVISION: 1>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: 01 Feb 2001>

=head1 PURPOSE:

Sends an email message.

=head1 EXAMPLE:

=head1 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

use strict;
use Mail::Send;
use Enigo::Common::ParamCheck qw(paramCheck);

sub mail {
  my ($param) = paramCheck([SUBJECT => 'U',
                RECIPIENTS => 'AR',
                BODY => 'U',
                CC => 'ARO',
                BCC => 'ARO',
                OTHER_HEADERS => 'HRO'],@_);

  my $mail = new Mail::Send;

  $mail->subject($param->{SUBJECT});

  foreach my $to (@{$param->{RECIPIENTS}}) {$mail->to($to)}

  foreach my $cc (@{$param->{CC}}) {$mail->cc($cc)}

  foreach my $bcc (@{$param->{BCC}}) {$mail->bcc($bcc)}

  foreach my $header (keys(%{$param->{OTHER_HEADERS}})) {
    my @values;
    if (ref($param->{OTHER_HEADERS}->{$header}) eq 'ARRAY') {
      @values = @{$param->{OTHER_HEADERS}->{$header}};
    } else {
      @values = ($param->{OTHER_HEADERS}->{$header});
    }
  }

  my $mail_handle = $mail->open;
  print $mail_handle $param->{BODY};
  $mail_handle->close();

  return undef;
}


1;
