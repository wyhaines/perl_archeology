#!/usr/bin/perl

use strict;

use Enigo::Common::Override {exit => ['Enigo::Common::Exception']};
use Enigo::Common::Log::Dispatch;
use Enigo::Common::Log::Dispatch::Screen;
use Enigo::Common::Log::Dispatch::Handle;
use Enigo::Common::Log::Dispatch::File;
use Enigo::Common::Log::Dispatch::Callback;
use Enigo::Common::Log::Dispatch::Email::MailSend;
use Enigo::Common::Log::Dispatch::Email::MailSendmail;
use Enigo::Common::Log::Dispatch::Email::MIMELite;
use IO::Scalar;
use Algorithm::Diff;
use Text::Wrap;
use Error qw(:try);

my $email_addr = $ARGV[0];
print "Testing Enigo::Common::Log::Dispatch\n";
print "  Test emails will go to $email_addr\n\n";

my $dispatcher;
my $handle;
my @tests = split(/;;;;;/,<<'ETESTS');
eval {
  $dispatcher = Enigo::Common::Log::Dispatch->new;
};

check("A dispatcher object can be created without errors.",
      $@,
      $@);
;;;;;
eval {
  $dispatcher->add
    (Enigo::Common::Log::Dispatch::Screen->new(min_level => 'minor'));
};

my $dt = $@;
$dt =~ s{\n}{}g;
check("Adding a dispatcher without a name throws the proper error.",
      ($dt !~ /No name was supplied/),
      $@); 
;;;;;
eval {
  $dispatcher->add
    (Enigo::Common::Log::Dispatch::Screen->new(name => 'test'));
};

my $dt = $@;
$dt =~ s{\n}{}g;
check("Adding a dispatcher without a minimum level throws the proper error.",
      ($dt !~ /minimum logging level/),
      $@); 
;;;;;
eval {
  $dispatcher->add
    (Enigo::Common::Log::Dispatch::Screen->new(name => 'test',
                                               min_level => 'major',
                                               max_level => 'minor'));
};

my $dt = $@;
$dt =~ s{\n}{}g;
check("Adding a dispatcher with a min_level greater than the max_level throws the proper error.",
      ($dt !~ /"3".+?"2"/),
      $@); 
;;;;
eval {
  $dispatcher->add
    (Enigo::Common::Log::Dispatch::Screen->new(name => 'test',
                                               min_level => 'this_is_wrong'));
};

my $dt = $@;
$dt =~ s{\n}{}g;
check("Adding a dispatcher with an invalid level throws the proper error.",
      ($dt !~ /this_is_wrong/),
      $@); 
;;;;
eval {
  $dispatcher->add
    (Enigo::Common::Log::Dispatch::Screen->new(name => 'screen',
                                               min_level => 'minor',
                                               stderr => 1));
};

check("A screen output destination can be added to the dispatcher.",
      $@,
      $@);
;;;;;
print "  [Capturing STDERR...]\n";
tie(*STDERR,'IO::Scalar');
eval {
  $dispatcher->major("\n  This is a major alert coming to you via the dispatcher.\n\n");
};
tied(*STDERR)->seek(0,0);
my $stderr_txt = join('',(tied(*STDERR)->getlines()));
untie *STDERR;

check("A logging call to the screen logger will complete accurately and without error.",
      ($stderr_txt !~ /major alert/),
      diff("\n  This is a major alert coming to you via the dispatcher.\n\n",
           $stderr_txt));
;;;;;
my $removed;
eval {
  $removed = $dispatcher->remove('screen');
};

check("A destination can be removed from the dispatcher.",
      ($@ or (! $removed)),
      $@);
;;;;;
$handle = IO::File->new("> /tmp/q_c_l_d_h.$$");
eval {
  $dispatcher->add
    (Enigo::Common::Log::Dispatch::Handle->new(name => 'handle',
                                               min_level => 'minor',
                                               handle => $handle));
};

check("An IO handle destination can be added to the dispatcher.",
      ($@ or (! -e "/tmp/q_c_l_d_h.$$")),
      $@);
;;;;;
eval {
  $dispatcher->major("This is another major logging message.\n");
};

check("A logging message can be written to an IO handle without error.",
      $@,
      $@);
;;;;;
$dispatcher->remove('handle');
$handle->close();
open(FILE,"</tmp/q_c_l_d_h.$$");
my $line = <FILE>;
close FILE;
unlink "/tmp/q_c_l_d_h.$$";

check("The logging message was written to the IO handle accurately.",
      ($line !~ /major logging message/),
      diff("This is another major logging message.\n",$line));
;;;;;
my $removed;
eval {
  $removed = $dispatcher->remove('handle');
};
eval {
  $dispatcher->add
    (Enigo::Common::Log::Dispatch::File->new(name => 'file',
                                             min_level => 'minor',
                                             filename => "/tmp/q_c_l_d_f.$$"));
};

check("A file destination can be added to the dispatcher.",
      ($@ or (! -e "/tmp/q_c_l_d_f.$$")),
      $@);
;;;;;
eval {
  $dispatcher->major("This is another major logging message.\n");
};

check("A logging message can be written to a file without error.",
      $@,
      $@);
;;;;;
$dispatcher->remove('file');
open(FILE,"</tmp/q_c_l_d_f.$$");
my $line = <FILE>;
close FILE;
unlink "/tmp/q_c_l_d_f.$$";

check("The logging message was written to the file accurately.",
      ($line !~ /major logging message/),
      diff("This is another major logging message.\n",$line));
;;;;;
my $removed;
eval {
  $removed = $dispatcher->remove('file');
};
eval {
  $dispatcher->add
    (Enigo::Common::Log::Dispatch::Callback->new
      (name => 'callback',
       min_level => 'minor',
       callback => sub {
         my %params = @_;
         print STDERR $params{message}}));
};

check("A callback destination can be added to the dispatcher.",
      $@,
      $@);
;;;;;
print "  [Capturing STDERR...]\n";
tie(*STDERR,'IO::Scalar');
eval {
  $dispatcher->major("\n  This is a major alert coming to you via the dispatcher.\n\n");
};
tied(*STDERR)->seek(0,0);
my $stderr_txt = join('',(tied(*STDERR)->getlines()));
untie *STDERR;

check("The callback destination works accurately and without error.",
      ($stderr_txt !~ /major alert/),
      diff("\n  This is a major alert coming to you via the dispatcher.\n\n",
           $stderr_txt));
;;;;;
my $removed;
eval {
  $removed = $dispatcher->remove('callback');
};
eval {
  $dispatcher->add
    (Enigo::Common::Log::Dispatch::Email::MailSend->new
      (name => 'email',
       min_level => 'minor',
       subject => 'MailSend test message',
       to => $email_addr,
       from => 'Dispatch_test@localhost',
       buffered => 0));
};

check("An MailSend email destination can be added to the dispatcher.",
      $@,
      $@);
;;;;;
if ($email_addr) {
  print <<ETXT;

Sending a test message.  Check the mail at $email_addr
to verify the message.

ETXT

  eval {
    $dispatcher->major("MailSend test message.  If you see this, it worked.\n");
  };

  check("A logging message can be emailed via MailSend without error.",
        $@,
        $@);
} else {
  check("No email address provided.  Skipping MailSend test.",
        0);
}
;;;;;
my $removed;
eval {
  $removed = $dispatcher->remove('email');
};
eval {
  $dispatcher->add
    (Enigo::Common::Log::Dispatch::Email::MailSendmail->new
      (name => 'email',
       min_level => 'minor',
       subject => 'MailSendmail test message',
       to => $email_addr,
       from => 'Dispatch_test@localhost',
       buffered => 0));
};

check("An MailSendmail email destination can be added to the dispatcher.",
      $@,
      $@);
;;;;;
if ($email_addr) {
  print <<ETXT;

Sending a test message.  Check the mail at $email_addr
to verify the message.

ETXT

  eval {
    $dispatcher->major("MailSendmail test message.  If you see this, it worked.\n");
  };

  check("A logging message can be emailed via MailSendmail without error.",
        $@,
        $@);
} else {
  check("No email address provided.  Skipping MailSendmail test.",
        0);
}
;;;;;
my $removed;
eval {
  $removed = $dispatcher->remove('email');
};
eval {
  $dispatcher->add
    (Enigo::Common::Log::Dispatch::Email::MIMELite->new
      (name => 'email',
       min_level => 'minor',
       subject => 'MailSend test message',
       to => $email_addr,
       from => 'Dispatch_test@localhost',
       buffered => 0));
};

check("A MIMELite email destination can be added to the dispatcher.",
      $@,
      $@);
;;;;;
if ($email_addr) {
  print <<ETXT;

Sending a test message.  Check the mail at $email_addr
to verify the message.

ETXT

  eval {
    $dispatcher->major("MIMELite test message.  If you see this, it worked.\n");
  };

  check("A logging message can be emailed via MIMELite without error.",
        $@,
        $@);
} else {
  check("No email address provided.  Skipping MIMELite test.",
        0);
}
$dispatcher->remove('email');
;;;;;
eval {
  $dispatcher->add(Enigo::Common::Log::Dispatch::File->new
    (name => 'debug',
     min_level => 'debug',
     max_level => 'debug',
     filename => "/tmp/debug.$$.test"));
  $dispatcher->add(Enigo::Common::Log::Dispatch::File->new
    (name => 'info',
     min_level => 'info',
     filename => "/tmp/info.$$.test"));
  $dispatcher->add(Enigo::Common::Log::Dispatch::File->new
    (name => 'minor',
     min_level => 'minor',
     max_level => 'minor',
     filename => "/tmp/minor.$$.test"));
  $dispatcher->add(Enigo::Common::Log::Dispatch::File->new
    (name => 'major',
     min_level => 'major',
     filename => "/tmp/major.$$.test"));
  $dispatcher->add(Enigo::Common::Log::Dispatch::File->new
    (name => 'critical',
     min_level => 'critical',
     max_level => 'critical',
     filename => "/tmp/critical.$$.test"));
};

check("A complex set of destinations with multiple different min_level and max_level specifications can all be set on the dispatcher without error.",
      $@,
      $@);
;;;;;
eval {
  $dispatcher->debug("debug\n");
  $dispatcher->info("info\n");
  $dispatcher->minor("minor\n");
  $dispatcher->major("major\n");
  $dispatcher->critical("critical\n");
};

my $debug;
my $info;
my $minor;
my $major;
my $critical;

{
  local $/;

  open(FILE,"</tmp/debug.$$.test");
  $debug = join('',<FILE>);
  close FILE;
  open(FILE,"</tmp/info.$$.test");
  $info = join('',<FILE>);
  close FILE;
  open(FILE,"</tmp/minor.$$.test");
  $minor = join('',<FILE>);
  close FILE;
  open(FILE,"</tmp/major.$$.test");
  $major = join('',<FILE>);
  close FILE;
  open(FILE,"</tmp/critical.$$.test");
  $critical = join('',<FILE>);
  close FILE;
}

check("Alerts at the various levels all go where they are supposed to when dealing with a complex set of destinations.",
      ($debug !~ /^debug\n$/s or
       $info !~ /^info\nminor\nmajor\ncritical\n$/s or
       $minor !~ /^minor\n$/s or
       $major !~ /^major\ncritical\n$/s or
       $critical !~ /^critical\n$/s),
      "debug:\n$debug\n\ninfo:\n$info\n\nminor:\n$minor\n\nmajor:\n$major\n\ncritical:\n$critical\n\n");

unlink "/tmp/debug.$$.test";
unlink "/tmp/info.$$.test";
unlink "/tmp/minor.$$.test";
unlink "/tmp/major.$$.test";
unlink "/tmp/critical.$$.test";

ETESTS


print "1..",scalar(@tests),"\n";
my $test_num;

foreach my $test (@tests)
  {
    eval($test);
    if ($@)
      {
        $test_num++;
        print "FATAL ERROR\n";
        print "$@\nnot ok $test_num\n$!";
      }
  }

{
  $test_num = 0;
  sub check
    {
      my $description = shift;
      my $rc = shift;
      my $failure_information = shift;
      $test_num++;
      print Text::Wrap::wrap('','    ',"$description\n");
      unless ($rc)
        {
          print "ok $test_num\n";
        }
      else
        {
          if (defined $failure_information)
            {
              print <<ETXT;
*****************************
    Failed test returned:
$failure_information
*****************************
ETXT
            }
          print "not ok $test_num\n";
        }
    }
}


sub diff
  {
    my $s1 = [split(/\n/,shift)];
    my $s2 = [split(/\n/,shift)];

    my $diffs = Algorithm::Diff::diff($s1,$s2);
    my $result;

    foreach my $chunk (@{$diffs})
      {
        foreach my $line (@{$chunk})
          {
            my ($sign, $lineno, $text) = @{$line};
            $result .= sprintf "%4d$sign %s\n", $lineno+1, $text;
          }
        $result .= "--------\n";
      }

    return $result;
  }

sub breakpoint {print $main::fifi++,"\n";return $main::fifi;}
