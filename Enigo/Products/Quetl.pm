#!/usr/bin/perl -wc
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: Quetl.pm

=head1 Enigo::Products::Quetl;

I<REVISION: $Revision: 1.1.1.1 $>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: $Date: 2001/12/17 02:28:37 $>

=head1 PURPOSE:

=head1 TODO:

Test test test.

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

package Enigo::Products::Quetl;

use strict;
use RPC::PlClient;
use Getopt::EvaP;
use Enigo::Common::Log::Dispatch;
use Enigo::Common::Log::Dispatch::Screen;
use Enigo::Common::Log::Dispatch::File;
use Enigo::Common::Log::Dispatch::Email::MailSendmail;
use Enigo::Common::Log::Dispatch::Email::MIMELite;
use Enigo::Common::Log::Dispatch::Callback;  
use Enigo::Common::Log::Dispatch::Base;  
use Proc::Daemon;
use Crypt::CBC;
use IPC::Shareable;
use LWP::UserAgent;
use XML::Parser::PerlSAX;
use XML::Grove;
use XML::Grove::Builder;
use Mail::Send;
use POSIX qw(:signal_h :sys_wait_h);
use Storable qw(freeze thaw);
use Data::Dumper;
use Term::ANSIColor;

use Enigo::Common::MethodHash;
use Enigo::Common::Filter qw(Quetl);
use Enigo::Common::SQL::SQL;
use Enigo::Common::ParamCheck qw(paramCheck);
use Error qw(:try);
use Enigo::Common::Exception qw(:IO :eval);
use Enigo::Common::Scheduler;
use Enigo::Products::Quetl::Client;

use Enigo::Common::Override::PerlExceptions qw(fork);
use Enigo::Products::Quetl::Loggers::logTransaction;

use Enigo::Common::Override {exit => [qw(Enigo::Products::Quetl::Loggers)]};
use vars qw($AUTOLOAD @ISA);

#This allows us to reference onject variables with method syntax, which
#makes for less mess on the screen when doing a whole bunch of assignments
#to object vars, especially if we're referencing a config object which can
#also be treated this way to get the data.  See the _init() method for
#the primary usage of this feature.
@ISA = qw(Enigo::Common::MethodHash);

($Enigo::Products::Quetl::VERSION) =
  '$Revision' =~ /\$Revision:\s+([^\s]+)/;

#These are just come "constants" that specify a paramCheck syntax string
#to verify that the named type of data item was passed.  These are used
#in paramCheck() calls in other subroutines.
sub _pc_name {return 'CD=/^[\w:]+/'}
sub _pc_action {return 'A'}
sub _pc_action_o {return 'AO'}
sub _pc_server {return 'CD=/^[\w\.]+/'}
sub _pc_port {return ['I',4455]}
sub _pc_user {return 'AN'}
sub _pc_password {return 'AN'}
sub _pc_cipher {return 'UR'}
sub _pc_cipher_o {return 'URO'}
sub _pc_time {return 'I'}
sub _pc_time_o {return 'IO'}
sub _pc_details {return 'U'}
sub _pc_details_o {return 'UO'}
sub _pc_state {return 'U'}
sub _pc_state_o {return 'UO'}
sub _pc_version {return 'U'}
sub _pc_compression {return 'UO'}
sub _pc_maxmessage {return 'IO'}
sub _pc_timeout {return 'IO'}


######################################################################
##### Constructor: new
######################################################################

=pod

=head2 CONSTRUCTOR_NAME: new

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 24 Sept 2001>

=head2 PURPOSE:

=head2 ARGUMENTS:

=head2 THROWS:

=head2 RETURNS:

=head2 EXAMPLE:

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub new {
  my ($proto) = shift;
  my ($class) = ref($proto) || $proto;
  my $self  = Enigo::Common::MethodHash->new();
  bless ($self, $class);
  $Enigo::Products::Quetl::self = $self;
  $self->_init(@_);
  return $self;
}


sub _init {
  my ($self) = shift;
  my ($param) = shift;

  $self->{CONFIG_CATALOG} = $param->{CONFIG_CATALOG};
  $self->{CONFIG_LABEL} = $param->{CONFIG};
  $self->_initConfig();
  $self->{CONFIG}->read($self->{CONFIG_LABEL});

  my $CONFIG = $self->{CONFIG};
  $self->DSN($CONFIG->DSN)
       ->USER($CONFIG->USER)
       ->AUTH($CONFIG->AUTH);
  $self->_initDatabase();

  $self->DEBUG_LOG($CONFIG->debug_log)
       ->INFO_LOG($CONFIG->info_log)
       ->MINOR_LOG($CONFIG->minor_log)
       ->MAJOR_LOG($CONFIG->major_log)
       ->CRITICAL_LOG($CONFIG->critical_log)
       ->DAEMON($CONFIG->daemon)
       ->ENCRYPTION_ALGORITHM($CONFIG->encryption_algorithm)
       ->ENCRYPTION_KEY($CONFIG->encryption_key)
       ->LOGGER_INDEX($CONFIG->logger_index)
       ->ERROR_THRESHOLD
         ($CONFIG->error_threshold ? $CONFIG->error_threshold : 3)
       ->ERROR_INTERVAL
         ($CONFIG->error_interval ? $CONFIG->error_interval : 60)
       ->ERROR_FILE($CONFIG->error_file);

  $self->{RPC_PARAMS}->{SERVER} = $CONFIG->host;
  $self->{RPC_PARAMS}->{PORT} = $CONFIG->port;
  $self->{RPC_PARAMS}->{USER} = $CONFIG->user;
  $self->{RPC_PARAMS}->{PASSWORD} = $CONFIG->password;

  eval(join('',
        '$self->{AUTOLOAD_INC} = [qw(',
        join(' ',split(/,/,$CONFIG->autoload_inc)),
        ')];'));

  $self->_processOptions();

  $self->{BUILDER} = new XML::Grove::Builder();
  $self->{PARSER} = new XML::Parser::PerlSAX(Handler => $self->{BUILDER});

  $self->{UA} = new LWP::UserAgent;
  $self->{UA}->agent
    ("MobileEnginesMonitor/$Enigo::UtilitySoftware::Monitor::Server::VERSION"
     . $self->{UA}->agent());


  # Create the processes for logging on 5 levels
  ################################################
  $self->{DISPATCHER} = new Enigo::Common::Log::Dispatch();
  foreach my $data ( ("debug^"     . $self->{DEBUG_LOG},
                        "info^"      . $self->{INFO_LOG},
                      "minor^"     . $self->{MINOR_LOG},
                      "major^"     . $self->{MAJOR_LOG},
                      "critical^"  . $self->{CRITICAL_LOG} ) )
  {
    # allow each level to log to multiple outputs.
    ##################################################
    my ($type, $info) = $data =~ /^(\w+)\^(.*$)/;
    my @destinations = split(/,/, $info);
    foreach my $destination (@destinations) {
      my ($type, $keys) = split(/;/, $destination,2);
      my @keys;

      # and multiple paramaters defining each output
      ##############################################
      foreach my $keyval (split(/\|/, $keys))
      {
        my ($key, $value) = $keyval =~ m/\s*(\w+)\s*=\s*(.*)\s*$/;
        push @keys, $key,$value;
      }
      $type = "Enigo::Common::Log::Dispatch::$type";
      $self->{DISPATCHER}->add($type->new(@keys));

    #Save this print statement for debugging logging initialization.
    ################################################################
    #print "Quetl.pm->init_logging  Level: $type, ".
    #      "\tDestinations: @destinations\n";
    }
  }

  # The next line makes the dispatcher accessable in other modules.
  ################################################################
  $Enigo::Products::Quetl::Dispatcher = $self->{DISPATCHER};


  # Write opening lines to log which don't email messages
  #########################################################
  my $time = POSIX::asctime(localtime(time));
  chomp($time);
  my $msg = "########################### ".
            "Starting Quetl pid: $$ \t $time  ".
            "###########################\n";

  $self->{DISPATCHER}->log(level => 'info', message => $msg);

  $self->{DISPATCHER}->log(level => 'debug', message => $msg);

  $self->{LOGGERS} = $self->_initLoggers();

  $self->{DISPATCHER}->log(level => 'debug',
               message => "Initialization completed\n");
  @Enigo::Products::Quetl::resurection_list = ();

  return undef;

}


#Connect to the database and check that the required tables
#exist, creating them if they do no.
sub _initDatabase {
  my ($self) = shift;

  $self->{SQL} = Enigo::Common::SQL::SQL->new({DSN => $self->{DSN},
                        USER => $self->{USER},
                        AUTH => $self->{AUTH},
                        ATTRIB => {PrintError => 0,
                               RaiseError => 1},
                        CONFIG_OBJECT => $self->{CONFIG}});
  $Enigo::Products::Quetl::SQL = $self->{SQL};

  my $sth;
  my $dbh = $self->{SQL}->get_dbh({DSN => $self->{DSN},
                   USER => $self->{USER},
                   AUTH => $self->{AUTH}},
                  ATTRIB => {PrintError => 0,
                         RaiseError => 1});
  $dbh->{PrintError} = 0;
  $dbh->{RaiseError} = 1;

#########  Create the details table if needed
  eval {
    $sth = $dbh->prepare('SELECT 1 FROM details');
    $sth->execute();
  };

  if ($@) {
    eval {
      $sth = $dbh->prepare(<<ESQL);
CREATE TABLE details (name CHAR(100),
                      action char(10),
              time CHAR(14),
              details CHAR(255))
ESQL
      $sth->execute();
    };
  }

#########  Create the transactions table if needed
  eval {
    $sth = $dbh->prepare('SELECT task from transactions');
    $sth->execute();
  };

  if ($@) {
    eval {
      $sth = $dbh->prepare(<<ESQL);
CREATE TABLE transactions (task CHAR(500),
                           date CHAR(140),
                           original_path CHAR(200),
                           bytes CHAR(140),
                           bof CHAR(10),
                           eof CHAR(10),
                           md5_value CHAR(500),
                           new_path CHAR(600),
                           validation CHAR(250))
ESQL
      $sth->execute();
    };
  }
#########  Create the filesManiped table if needed
  eval {
    $sth = $dbh->prepare('SELECT task from filesManiped');
    $sth->execute();
  };

  if ($@) {
    eval {
      $sth = $dbh->prepare(<<ESQL);
CREATE TABLE filesManiped (task CHAR(50),
                           date CHAR(14),
                           source_path_file CHAR(200),
                           action CHAR(25),
                           new_path_file CHAR(600),
                           bytes CHAR(14))
ESQL
      $sth->execute();
    };
  }

#########  Create the status table if needed
  $sth = undef;
  eval {
    $sth = $dbh->prepare('SELECT 1 from status');
    $sth->execute();
  };

  if ($@) {
    eval {
      $sth = $dbh->prepare(<<ESQL);
CREATE TABLE status (name CHAR(100),
                     time char(14),
             status CHAR(1),
                     pid char(10))
ESQL
      $sth->execute();
    };
  }
}


sub _initConfig {
  my ($self) = shift;
  $self->{CONFIG} = new Enigo::Common::Config();
  $self->{CONFIG}->parse($self->{CONFIG_CATALOG});
  $Enigo::Products::Quetl::Config = new Enigo::Common::Config();
  $Enigo::Products::Quetl::Config->parse($self->{CONFIG_CATALOG});
  return undef;
}


sub _processOptions {
  my ($self) = shift;
  my @PDT = split("\n",<<'EPDT');
PDT Quetl
  daemon, d: switch
  version, v: switch
  task, t: string
  dump, u: switch
PDTEND optional_file_list
EPDT
  my @MM = split("\n",<<'EMM');
Quetl [-d|-daemon] [-v|-version] [-t|-task NAME]
.configFile
  The config file is essential to setting various paramaters for the 
  programs operation.  These include the DSN, USER, Password, perl
  libraries for auto loading, the logger index file and for 
  specifying output at all logging levels.  The config file defaults
  to /opt/platform/Quetl/config/Quetl At this time it
  CAN NOT be overridden on the command line.
.daemon
  Tells Quetl whether it should fork itself off as a daemon or not.
  This defaults to on.
.version
  The version number of Quetl.
.task
  This specifies a specific task to execute.  Quetl will invoke
  this task and this task only and will do so immediately, running
  though it only once, then exiting.  An error will be returned
  if this task can not be found.
.dump
  Dumps the code for each task after the code has passed through
  all of the source filters.
EMM
  my %opts;
  EvaP(\@PDT,\@MM,\%opts);

  if ($opts{configFile} and ! -e $opts{configFile}) {
    throw Enigo::Common::Exception::IO::File::NotFound
      ($opts{configFile});
  }

  $self->{DAEMON} = $opts{daemon} if $opts{daemon};
  $self->{OPTS} = \%opts;

  my %structure;
  foreach my $arg (@ARGV) {
    my ($name,$value) = $arg =~ /^(\w+)\s*=\s*(.*)$/;
    push @{$structure{$name}},$value;
  }

  #The my'd variable code in here needs to go away.  It remains
  #so that some early code that rely's on it doesn't break before
  #I have a chance to fix it to use %CLVAR instead.
  my $code = "my %CLVAR;\n";
  foreach my $name (keys %structure) {
    if (scalar(@{$structure{$name}}) > 1) {
      $code .= join('',
            "my \@$name = (",
            (map {"\"$_\""}
             @{$structure{$name}}),
            ");\n");
      $code .= join('',
            "\$CLVAR{$name} = [",
            (map {"\"$_\""}
             @{$structure{$name}}),
            "];\n");
    } else {
      $code .= "my \$$name = \"$structure{$name}->[0]\";\n";
      $code .= "\$CLVAR{$name} = \"$structure{$name}->[0]\";\n";
    }
  }

  #Isn't this, uhm, CLeVeR variable naming?
  $self->{CLVAR_CODE} = $code;

  #bk added 
  # All loggers need dw_home set so putting that code here.
  #########################################################
  $self->{HOME_CODE} = join("",
            'my $dw_home = exists $CLVAR{dw_home} ? $CLVAR{dw_home} : $ENV{DW_HOME};',
            '$dw_home = $dw_home ? $dw_home : "/opt/dw";',
            'my $base = "$dw_home/data";');

  return undef;
}


######################################################################
##### Method: _initLoggers
######################################################################

=pod

=head2 METHOD_NAME: _initLoggers

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 28 Jul 2000>

=head2 PURPOSE:

Internal routine to read the processes from their files and set
them up for invocation.  This method is not part of the public
interface to this class, but is being documented here to provide
important background information regarding monitor files and
how they are parsed.

=head2 ARGUMENTS:

none

=head2 RETURNS:

An array ref of processes.

=head2 THROWS:

  Enigo::Common::Exception::IO::File::NotReadable
  Enigo::Common::Exception::IO::File::NotCloseable

=head2 EXAMPLE:

none

=head2 TODO:

test test test

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub _initLoggers {
  my ($self) = shift;

  #We don't want logger code being able to exit a logger process.
  Enigo::Common::Override->override(exit => sub {return @_});

  my $processes = [];
  my %fetched;

  $self->{ZERO_TIME} = time();
  $self->{ZERO_COUNT} = 1;

  if ($self->{DAEMON} and !$self->{OPTS}->{task}) {
    $self->{DISPATCHER}->log(level => 'info',
                 message => "Forking and backgrounding....\n");
    Proc::Daemon::Init();

    #Proc::Daemon::Init() will close all open file descriptors.
    #This means that our handle to our logfile gets closed, too,
    #darn it all.  Sooooo, we recreate our dispatcher here.
    $self->{DISPATCHER} = new Log::Dispatch();

    $self->{DISPATCHER}->log(level => 'info',
                 message => "Finished forking; server daemonized\n");
    $self->{DISPATCHER}->log(level => 'debug',
              message => "***********************************************\n".
                         "***********************************************\n".
                         "***********************************************\n".
                         "***********************************************\n".
                            "Hey, if this doesn't".
                         " make it into the log when run in deamon mode".
                         "\nThere is more work to do.\n".
                         "***********************************************\n".
                         "***********************************************\n".
                         "***********************************************\n".
                         "***********************************************\n");
  }

  $self->{CIPHER} = '';
  $self->{CIPHER} = Crypt::CBC->new($self->{ENCRYPTION_KEY},
                    $self->{ENCRYPTION_ALGORITHM})
    if $self->{ENCRYPTION_ALGORITHM};

  $self->{DISPATCHER}->log(level => 'debug',
               message => "Creating new RPC::PlClient\n");

  #Fork time.  At this point, we fork off a seperate process for each of
  #the different processes.  These will all communicate with the parent
  #process via a shared memory segment.

  #First, though, before we start forking, turn on a fork() override
  #that will cause fork() to throw exceptions on failure.  Makes
  #catching this condition a little bit more cleaner to you,
  #as someone who is trying to read this code.
  Enigo::Common::Override::PerlExceptions->override(qw(fork));

  my $count = 0;
  open(LOGGER_INDEX_FILE,$self->{LOGGER_INDEX}) ||
    throw Enigo::Common::Exception::IO::File::NotReadable
      ($self->{LOGGER_INDEX});

  while (my $line = <LOGGER_INDEX_FILE>) {
    #Remove comments.
    $line =~ s/\#(.*)$//g if (index($line,'#') >= 0);

    #Skip if the line is blank or just whitespace.
    next if ($line =~ /^\s*$/);

    #If the line starts with a '!' character, the task that the
    #remainder of the line points will be will valid for command
    #line specific invocation, but will not be vivified in
    #daemon mode.
    my $do_not_live = 1 if ($line =~ /^\s*!/);
    $line =~ s/^\s*!//;

    #Prune leading whitespace.
    $line =~ s/^\s*// if ($line =~ /^\s/);

    #If it's not in URI format (not a very bombproof regexp to check
    #this, I admit) assume that we want a file, and construct a
    #file URI.
    unless ($line =~ m|^\w+:/|) {
      $line = "/$line" unless (index($line,'/') == 0);
      $line = "file:$line";
    }
    chomp($line);

    #If it turns out we've already loaded this module,
    #don't do it again.
    #The question is, is this necessary/useful, and does doing this
    #restrict some other useful functionality?
    next if ($fetched{$line});

    #Let's go get it.
    my $result = 
      $self->{UA}->request(HTTP::Request->new(GET => $line));
    next unless ($result->is_success);

    $fetched{$line}++;
    my $content = $result->content;

    *Enigo::Products::Quetl::Loggers::AUTOLOAD = \&_AUTOLOAD;

    #Got it.  Make it live!  Or, if we are running is single
    #task mode, check to see if this is the one that we want.
    unless ($self->{OPTS}->{task} or $do_not_live) {
      $self->{PROCESSES}->[$count] = $content;
      $self->_logger($self->{PROCESSES}->[$count],$count);
      $count++;
    } else {
      my $logger = $self->_parse_logger($content);
      if ($logger->{NAME} eq $self->{OPTS}->{task}) {
    $self->{PROCESSES}->[$count] = $content;
    $self->_logger($self->{PROCESSES}->[$count],$count);
    $count++;
    last;
      }
    }
  }

  close(LOGGER_INDEX_FILE) ||
    throw Enigo::Common::Exception::IO::File::NotCloseable
      ($self->{LOGGER_INDEX});

  throw Enigo::Common::Exception::General
    ({TYPE => 'TaskNotFound',
      TEXT => "Task $self->{OPTS}->{task} was not found."})
      if (!$count and $self->{OPTS}->{task});

  return $processes;
}


sub _parse_logger {
  my ($self) = shift;
  my ($content) = shift;

  my $grove;

  eval {
    $grove = $self->{PARSER}->parse(Source => {String => $content});
  };

  if ($@) {

    my $error_text = $@;
    my ($line) = $@ =~ / at line (\d+)/;
    my $zero_adjusted_line = $line - 1;
    my $first_context_line =
      $zero_adjusted_line > 4 ? $zero_adjusted_line - 5 : 0;
    my $first_context_count =
      $first_context_line ? 5 : $zero_adjusted_line;
    my $text;

    my $regexp = '^';
    $regexp .= '(?:[^\n]*\n){' . $first_context_line . '}'
      if ($first_context_line > 0);
    $regexp .= '?(' . '[^\n]*\n' x $first_context_count;
    $regexp .= ')([^\n]*(?:\n|$))(' . '[^\n]*(?:\n|$)' x 2;
    $regexp .= ')';
    $content =~ /^$regexp/m;
    my $first_context = $1;
    my $line = $2;
    my $last_context = $3;
    $text = join('',
         "Error: XMLParser: $@\n",
         $1,
         color('bold'),
         $2,
         color('reset'),
         $3,
         "\n");
    print STDERR $text;
    exit();
  }

  my $logger = {NAME => '',
        MODE => 'individual',
        INTERVAL => 60,
        SERVERS => [],
        CODE => ''};

  foreach my $item (@{$grove->{Contents}}) {
    next unless (ref($item) !~ /XML::Grove::Characters/);

    if (ref($item) =~ /::Element/ and
    ($item->{Name} =~ /^logger$/i or $item->{Name} =~ /^quetl$/i)) {
      $logger->{NAME} = $item->{Attributes}->{name};
      $logger->{INTERVAL} = $item->{Attributes}->{interval}
    if defined($item->{Attributes}->{interval});
      $logger->{MODE} = $item->{Attributes}->{mode}
    if defined($item->{Attributes}->{mode});

      for my $logger_item (@{$item->{Contents}}) {
    next unless (ref($logger_item) !~ /XML::Grove::Characters/);
    if (ref($logger_item) =~ /::Element/ and
        $logger_item->{Name} =~ /code$/i) {
      $logger->{CODE} = join('',map {$_->{Data}}
                   @{$logger_item->{Contents}});
      $logger->{CODE} =~ s/^\s*//;
      $logger->{CODE} =~ s/\s*$//;
    }
    elsif (ref($logger_item) =~ /::Element/ and
           $logger_item->{Name} =~ /^server$/i) {
      my $server = {ADDRESS => '',
            SERVICE => '',
            PORT => '4457',
            USER => '',
            PASSWORD => '',
            VERSION => '1.0',
            TIMEOUT => '',
            MAXMESSAGE => '65536',
            COMPRESSION => '0',
            ENCRYPTION_ALGORITHM => '',
            ENCRYPTION_KEY => ''};
      $server->{ADDRESS} = $logger_item->{Attributes}->{address};
      $server->{SERVICE} = $logger_item->{Attributes}->{service};
      $server->{PORT} = $logger_item->{Attributes}->{port}
        if defined($logger_item->{Attributes}->{port});
      $server->{USER} = $logger_item->{Attributes}->{user};
      $server->{PASSWORD} = $logger_item->{Attributes}->{password};
      $server->{VERSION} = $logger_item->{Attributes}->{version}
        if defined($logger_item->{Attributes}->{version});
      $server->{TIMEOUT} = $logger_item->{Attributes}->{timeout};
      $server->{MAXMESSAGE} = $logger_item->{Attributes}->{maxmessage}
        if defined($logger_item->{Attributes}->{maxmessage});
      $server->{COMPRESSION} = $logger_item->{Attributes}->{compression}
        if defined($logger_item->{Attributes}->{compression});
      $server->{ENCRYPTION_ALGORITHM} = $logger_item->{Attributes}->{encryption_algorithm};
      $server->{ENCRYPTION_KEY} = $logger_item->{Attributes}->{encryption_key};
      push @{$logger->{SERVERS}},$server;
    } elsif (ref($logger_item) =~ /::Element/ and
         $logger_item->{Name} =~ /args$/i) {
      my $arg_code = join('',map {$_->{Data}}
                  @{$logger_item->{Contents}});
      $arg_code =~ s/^\s*//;
      $arg_code =~ s/\s*$//;
      push @{$logger->{SERVERS}},$arg_code;
    }
      }
    }
  }

  return undef unless ($logger->{CODE} and
               $#{$logger->{SERVER}});

  unless ($self->{OPTS}->{task} and
      !($self->{OPTS}->{task} eq $logger->{NAME}))
    {
      $logger->{SCHEDULER} = new Enigo::Common::Scheduler;
      $logger->{SCHEDULER}->addEntry({TIME => $logger->{INTERVAL},
                      LABEL => $logger->{NAME}});

      $Enigo::Products::Quetl::Loggers::self = $self;

      #Create the logger subroutine.
      my $code = join("\n",
              'package Enigo::Products::Quetl::Loggers;',
              "sub $logger->{NAME}_Code {",
              $self->{CLVAR_CODE},
            $self->{HOME_CODE},                         #bk added
              $logger->{CODE},
              "};",
              'package Enigo::Products::Quetl;');

      my $time = POSIX::asctime(localtime(time));
      chomp($time);
      $self->{DISPATCHER}->log
    (level => 'debug',
     message => "$$: Filtering and creating Enigo::Products::Quetl::Loggers::$logger->{NAME}_Code at $time.\n");
      $code = Enigo::Common::Filter->filter($code);
      print "Enigo::Products::Quetl::Loggers::$logger->{NAME}_Code\n\n$code"
    if $self->{OPTS}->{dump};
      eval($code);
      throw Enigo::Common::Exception::Eval($code) if ($@);
    }
  return $logger;
}


sub _AUTOLOAD {
  (my $path = "$AUTOLOAD.pm") =~ s{::}{/}g;
  $Enigo::Products::Quetl::Dispatcher->log
    (level => 'debug',
     message => "$$: Attempting to autoload $AUTOLOAD\n");
  foreach my $directory (@{$Enigo::Products::Quetl::self->{AUTOLOAD_INC}}) {
    $Enigo::Products::Quetl::Dispatcher->log
      (level => 'debug',
       message => "$$: Checking $directory/$path\n");
    next unless -r "$directory/$path";

    my $code;
    {
      $Enigo::Products::Quetl::Dispatcher->log
    (level => 'debug',
     message => "$$: Autoloading $AUTOLOAD from $directory/$path\n");
      local $/;
      open(INC,"<$directory/$path") or eval {
    my $time = POSIX::asctime(localtime(time));
        chomp($time);
    $Enigo::Products::Quetl::Dispatcher->log
      (level => 'alert',
       message => "$$: Autoload of $directory/$path failed at $time.\n");
    throw Enigo::Common::Exception::IO::File::NotReadable("$directory/$path");
      };

      $code = <INC>;
      close INC;
    }

    my $current_package = caller() ? caller() : 'main';
    my ($autoload_package) = $AUTOLOAD =~ /^((?:\w+::)*)/;
    $autoload_package = $autoload_package ? caller() : 'main';
    eval(join("\n",
          "package $autoload_package;",
          $code,
          "package $current_package;"));
    if ($@) {
      my $time = POSIX::asctime(localtime(time));
      chomp($time);
      $Enigo::Products::Quetl::Dispatcher->log
    (level => 'alert',
     message => "$$: Eval of $directory/$path failed at $time because:\n$@\n");
      throw Enigo::Common::Exception::Eval($code);
    }

    goto &$AUTOLOAD;
  }
}


sub run {
  my ($self) = shift;

  #The only way execution will ever reach here is if this is the
  #parent process.  The duty of the parent is to watch the message
  #queue in shared memory for messages from any of the children.
  #If any are seen, the parent will log them to the database.
  #The parent also keeps an eye on each of the child processes,
  #and will start a new process if any of the children should die.
  #There is a built in pause in this processes, however, so that
  #if something is very, very wrong, the constant fork and reap
  #loop that occurs when the logger repeatedly dies hopefully
  #doesn't cause undue stress on the machine.
  #The parent also tries to cleanly harvest each of its children
  #should it find itself killed/exited.

  #We need to make sure that our signals are not being blocked.
  my $chld_set = POSIX::SigSet->new(SIGCHLD);
  my $full_set = POSIX::SigSet->new(SIGHUP,
                    SIGTERM,
                    SIGQUIT,
                    SIGINT,
                    SIGCHLD);
  sigprocmask(SIG_UNBLOCK,$full_set);

  #Next, setup signal handlers

  $SIG{CHLD} = \&_sig_CHLD_handler;
  $SIG{INT} = \&_cleanup_and_exit;
  $SIG{QUIT} = \&_cleanup_and_exit;
  $SIG{TERM} = \&_cleanup_and_exit;
  $SIG{HUP} = \&_reinitialize;

  my $time = POSIX::asctime(localtime(time));
  chomp($time);
  $self->{DISPATCHER}->log(level => 'info',
               message => "$$: Starting Quetl main loop at $time.\n");

  my $forever = 1;
  while ($forever) {
    my $count = 0;
    my $short_sleep = 0;
    #Block SIGCHLD so that it won't interrupt us while we deal with locking
    #shared memory and going through it.

    sigprocmask(SIG_BLOCK,$chld_set);

    #If there was a message, we are just going to do a short sleep,
    #as more messages may be coming in.  If there was not message,
    #we'll wait a full second before checking again.
    $short_sleep = $self->_handle_message_queue();
    $self->_handle_resurection_list();
    $self->_handle_serious_errors();
    sigprocmask(SIG_UNBLOCK,$full_set);

    if ($short_sleep) {
      select(undef,undef,undef,.1);
    } else {
      sleep 1;
    }
  }

  return undef;
}


sub _handle_message_queue {
  my $self = shift;
  my $count = 0;
  my $short_sleep = 0;

  #Lock the message queue and then see if there is anything on there
  #that needs to be shifted off and logged.
  (tied @Enigo::Products::Quetl::message_queue)->shlock;
  eval {$count = $#Enigo::Products::Quetl::message_queue};
  while ($count > 0) {
    $short_sleep++;
    $self->_log_state
      (thaw
       (splice @Enigo::Products::Quetl::message_queue,1,1));
    $count = 0;
    eval {$count = $#Enigo::Products::Quetl::message_queue};
  }
  undef @Enigo::Products::Quetl::message_queue;
  @Enigo::Products::Quetl::message_queue = ('NULL');

  #Unlock the message queue.
  (tied @Enigo::Products::Quetl::message_queue)->shunlock;

  return $short_sleep;
}


sub _handle_resurection_list {
  my $self = shift;
  my $count = 0;

  #Lock the resurection list and see if there are any processes that
  #need revivification.
  (tied @Enigo::Products::Quetl::resurection_list)->shlock;
  eval {$count = $#Enigo::Products::Quetl::resurection_list};
  if ($count > 0 and $self->{OPTS}->{task}) {
    (tied @Enigo::Products::Quetl::resurection_list)->shunlock;
    _cleanup_and_exit();
  }

  while ($count > 0) {
    my ($number) =
      splice @Enigo::Products::Quetl::resurection_list,1,1;
    $self->_logger($self->{PROCESSES}->[$number],$number);
    select(undef,undef,undef,.5);
    $count = 0;
    eval {$count = $#Enigo::Products::Quetl::resurection_list};
  }
  #Then unlock the resurection list.
  undef @Enigo::Products::Quetl::resurection_list;
  @Enigo::Products::Quetl::resurection_list = ('NULL');
  (tied @Enigo::Products::Quetl::resurection_list)->shunlock;

  return undef;
}


sub _handle_serious_errors {
  my $self = shift;
  my $count = 0;

  (tied @Enigo::Products::Quetl::serious_errors)->shlock;

  eval {$count = $#Enigo::Products::Quetl::serious_errors};
  while ($count >= $self->{ERROR_THRESHOLD}) {
    splice(@Enigo::Products::Quetl::serious_errors,1,1);
  }
  eval {$count = $#Enigo::Products::Quetl::serious_errors};


  if ($count ==
      ($self->{ERROR_THRESHOLD} -1)) {
    my $difference =
      $Enigo::Products::Quetl::serious_errors[$count] -
    $Enigo::Products::Quetl::serious_errors[1];
    if ($difference <= $self->{ERROR_INTERVAL})
      { #Serious badness.
    #Kill the children.
    #Log the situation.
    $self->{DISPATCHER}->log(level => 'error',
                 message => <<EERROR);
Quetl exiting
There were $self->{ERROR_THRESHOLD} serious errors in $difference seconds,
which exceeds the thresholds for this monitor.
EERROR
    #If a file containing code to run in this condition exists,
    #slurp it and eval it.  Any errors that arise from this code
    #are trapped and logged.
    kill 1,(keys %Enigo::Products::Quetl::ptp);

    if ($self->{ERROR_FILE}) {
      eval {
        do $self->{ERROR_FILE};
      };
      $self->{DISPATCHER}->log(level => 'error',
                   message => <<EERROR);
The catastrophic failure code for Quetl, found at $self->{ERROR_FILE},
failed with the following error:

$@
EERROR
    }
    exit();
      }
  }
  (tied @Enigo::Products::Quetl::serious_errors)->shunlock;

  return undef;
}


sub _logger {
  my ($self) = shift;
  my ($content) = shift;
  my ($logger_number) = shift;
  my $msg;

  my $pid;
  $self->{PPID} = $$;

  try {
    my $time = POSIX::asctime(localtime(time));
    chomp($time);
    $self->{DISPATCHER}->log
      (level => 'info',
       message => "$$: Forking Quetl task process $logger_number at $time.\n");

    $pid = fork();
  } catch Enigo::Common::Exception with {
    #If we experience a failure of fork, we don't die, but
    #rather we log this failure, pause for a second in case
    #the cause was transient (so that hopefully the next
    #fork will succede), and then push this logger onto the
    #resurection list so that we will return to it and try
    #to revive it later.  We also note the time of this
    #event in an array.  This array will be periodically
    #checked, and if a predefined threshold of serious errors
    #occurs in less than X seconds, the Monitor will issue
    #a major exception with alerting, and will close up shop.
    if (ref($_[0])) {
      $self->_initialize_shared_memory_for_parent()
    unless ($self->_shared_memory_is_initialized());
      my $exception = shift;
      $self->{DISPATCHER}->log(level => 'error',
                   message => $exception->stringify);
      push(@Enigo::Products::Quetl::resurection_list,
       $logger_number);
      push(@Enigo::Products::Quetl::serious_errors,
       time());
      return undef;
    }
  };

  if ($pid) {
    $self->_initialize_shared_memory_for_parent()
      unless ($self->_shared_memory_is_initialized());
    #The parent's execution path comes through here.
    $Enigo::Products::Quetl::ptp{$pid} = 
      $logger_number;

    return $pid;
  }
  #####
  #// And the child's execution path comes down through here.
  #// Here on out is the code to actually support probing.
  #####

  #####
  #// We need to make sure that our signals are not being blocked.
  #####
  my $full_set = POSIX::SigSet->new(SIGHUP,
                    SIGTERM,
                    SIGQUIT,
                    SIGINT);
  sigprocmask(SIG_UNBLOCK,$full_set);

  #####
  #// And that we don't have any inherited handlers or anything
  #// fun like that.
  #####

  $SIG{CHLD} = 'DEFAULT';
  $SIG{INT} = \&_last_gasp;
  $SIG{QUIT} = \&_last_gasp;
  $SIG{TERM}= \&_last_gasp;
  $SIG{HUP} = \&_last_gasp;

  #####
  #// Do the work to read the logger definition and create the required
  #// subroutine.
  #####
  my $logger = $self->_parse_logger($content);

  $0 = "Quetl -- $logger->{NAME}";
  $self->_initialize_shared_memory_for_child();
  $logger->{SCHEDULER}->buildInitialQueue();

  my $forever = 1;
  my %__arg_sub;
  while ($forever) { #forever loop#
      $forever = 0 if ($self->{OPTS}->{task});
    my $args;
    my ($current) = $logger->{SCHEDULER}->checkQueue();
    $self->_log({NAME => $logger->{NAME},
         ACTION => 'SLEEP',
         TIME => time(),
         DETAILS => join('',$current->[0]->[1] - time(),' seconds'),
         STATE => 's'});
    unless ($self->{OPTS}->{task}) {
      sleep($current->[0]->[1] - time());
    };
    $self->_log({NAME => $logger->{NAME},
         ACTION => 'RUN',
         TIME => time(),
         DETAILS => '',
         STATE => 'r'});

    if ($logger->{MODE} eq 'individual') {
      if (scalar(@{$logger->{SERVERS}})) {
    foreach my $server (@{$logger->{SERVERS}}) {
      unless (ref($server)) {
        $args = $server;
        next;
      }
      my @args;

      sigprocmask(SIG_BLOCK,$full_set);
      $self->_log({NAME => $logger->{NAME},
               ACTION => 'RPC',
               TIME => time(),
               DETAILS => join('|',
                       $server->{ADDRESS},
                       $server->{SERVICE}),
               STATE => 'a'});
      if ($args) {
        no strict 'refs';
        unless (defined $__arg_sub{$args}) {
          eval <<ECODE;
\$__arg_sub{qq($args)} = sub {
  $self->{CLVAR_CODE}
  $args
};
ECODE
            }

        @args = &{$__arg_sub{qq($args)}}($server);
        use strict 'refs';
      }
     $msg = "making call to RPCServer with:\n\t SERVER: $server @{[%$server]} \n\t ARGS: @args \n";
     $self->{DISPATCHER}->log(level   => 'debug',
                              message => "$msg");

     # Make call to RPCServer
     #########################
      my @results;
      eval {
        @results = $self->_make_RPC_call({SERVER => $server,
                          ARGS => \@args});
      };
     $self->{DISPATCHER}->log(level   => 'debug',
             message => "\t ERROR from RPCServer when requesting files: \n".
             "\t########################################################\n".
             "$@ \n".
             "\t########################################################\n") if $@;
      print STDERR "ERROR from RPCServer when requesting files.\n" if $@;


    #bk     ####################################################
    # Test the integrity of each packet and handle appropriately
    ############################################################
    my $prefix = "Quetl.pm->packet test:";
    my %test = @results;
    foreach my $key (keys %test) {
      $msg = undef;
      my $packetInfo = 
                       "\t File: $key\n".
                       "\t Bytes Data: ". length($test{$key}->[0]) ." \n".
                       "\t BOF:        ". $test{$key}->[1] ." \n".
                       "\t md5_p:      ". $test{$key}->[2] ." \n".
                       "\t EOF:        ". $test{$key}->[3] ." \n".
                       "\t md5_f:      ". $test{$key}->[4] ." \n";
      # Test packets for completeness

      # Does the packet have a file name?
      ###################################
      if ($key =~ m/^\s*$/ )
      {
        $msg = "Packet missing file name: \n";
        $key = "missing file name";
        $test{$key}->[2] = "missing_file_name";
      }
      # Does the packet have MD5 hashes?
      ##################################
      elsif ( !defined($test{$key}->[2]) || $test{$key}->[2] =~ m/^$/   ||
              !defined($test{$key}->[4]) || $test{$key}->[4] =~ m/^$/     )
      {
        $msg = "Packet missing MD5 hash: $key\n ";
        $test{$key}->[2] = "missing_md5_hash";
      }

      # Does the packet have a file data?
      ###################################
      elsif (!defined($test{$key}->[0]) || length($test{$key}->[0]) == 0)
      {
        $msg = "Packet contains no log data: $key\n";
      }

      $self->{DISPATCHER}->log(level   => 'major',
                               message => "$msg\n") if (defined($msg));
      $self->{DISPATCHER}->log(level   => 'info',
                               message => "    ${msg}\nAssociated data:\n$packetInfo\n") if (defined($msg));


      # Calculate and compare the MD5 hash values 
      ############################################
      my $rpcHash = $test{$key}->[2];
      my $md5 = Digest::MD5->new;
      $md5->add($test{$key}->[0]);
      my $hash = $md5->b64digest();
      $msg = "\nQuetl.pm->packet test: File: $key \t(qpt)\n".
                "$packetInfo".
                "\t MD5 calculated: $hash \t(qpt)\n";
      $self->{DISPATCHER}->log(level   => 'info',
                               message => "$msg");

      # Inform RPCServer of packet transfer integrity & remove bad packets
      ####################################################################
      my @hsArgs; 
      if ( $rpcHash eq $hash )
      {
        # logTransaction will be handled when packet is written to a file.
        @hsArgs = ($key, 1);
        $msg =  "\t Passes test, Setup for RPCServer call: \t(qpt)\n".
                "\t Server: @{[%$server]} \t(qpt)\n".
                "\t Params: @hsArgs \t(qpt)\n";
        $self->{DISPATCHER}->log(level   => 'debug',
                                 message => "$msg");
      } else
      {
        logTransaction({TASK => $lc::task,
                        ORIGINAL_PATH => $key,
                        BYTES => length( $test{$key}->[0] ),
                        BOF => $test{$key}->[1],
                        EOF => $test{$key}->[3],
                        MD5_VALUE => $test{$key}->[2],
                        NEW_PATH => "not established",
                        VALIDATION => "failed_packet",
                        DATE => time()            });
        @hsArgs = ($key, 0);
        $msg =  "\t Fails test, Setup for RPCServer call: \t(qpt)\n".
                "\t Server: @{[%$server]} \t(qpt)\n".
                "\t Params: @hsArgs \t(qpt)\n";
        $self->{DISPATCHER}->log(level   => 'debug',
                                 message => "$msg");
        $self->{DISPATCHER}->log(level   => 'major',
                                 message => "Packet level validation failed: $key\n\n");
        delete($test{$key});
      }
      my @response;
      eval {
            @response = $self->_make_RPC_call({SERVER => $server,
                           SERVICE => 'confirm_transfer',
                                               ARGS   => \@hsArgs});
           };
      $self->{DISPATCHER}->log(level   => 'debug',
             message => "\t RESPONSE from RPCServer: @response\n");
      $self->{DISPATCHER}->log(level   => 'debug',
             message => "\t ERROR from RPCServer: \n".
             "\t######################################################\n".
             "$@ \n".
             "\t######################################################\n") if $@;
      $msg = "ERROR from RPCServer in packet validation response ($key).\n" if $@;
      $self->{DISPATCHER}->log(level   => 'major',
                               message => "$msg") if $@;
    }  # End loop handling packet validation
    @results = %test;
    #########################################################

      $self->_log({NAME => $logger->{NAME},
               ACTION => 'ERROR',
               TIME => time(),
               DETAILS => $@,
               STATE => 'n'})
        if $@;

      $self->_log({NAME => $logger->{NAME},
               ACTION => 'PROCESS',
               TIME => time(),
               DETAILS => "$logger->{NAME}_Code",
               STATE => 'p'});
      eval {
        no strict 'refs';
        &{"Enigo::Products::Quetl::Loggers::$logger->{NAME}_Code"}($server, @results);  #bk added server
        use strict 'refs';
      };
     $self->{DISPATCHER}->log(level   => 'debug',
             message => "Response from RPCServer: $@\n") if $@;
     print STDERR $@ if $@;

      $self->_log({NAME => $logger->{NAME},
               ACTION => 'ERROR',
               TIME => time(),
               DETAILS => $@,
               STATE => 'n'})
        if $@;

      sigprocmask(SIG_UNBLOCK,$full_set);

      $self->_log({NAME => $logger->{NAME},
               ACTION => 'RUN',
               TIME => time(),
               DETAILS => '',
               STATE => 'r'});
    }
      } else {
    $self->_log({NAME => $logger->{NAME},
             ACTION => 'PROCESS',
             TIME => time(),
             DETAILS => "$logger->{NAME}_Code",
             STATE => 'p'});

    sigprocmask(SIG_BLOCK,$full_set);

    eval {
      no strict 'refs';
      &{"Enigo::Products::Quetl::Loggers::$logger->{NAME}_Code"}();
      use strict 'refs';
    };
        print STDERR $@ if $@;
    $self->_log({NAME => $logger->{NAME},
             ACTION => 'ERROR',
             TIME => time(),
             DETAILS => $@,
             STATE => 'n'})
      if $@;

    sigprocmask(SIG_UNBLOCK,$full_set);
    
    $self->_log({NAME => $logger->{NAME},
             ACTION => 'RUN',
             TIME => time(),
             DETAILS => '',
             STATE => 'r'});
      }
    } else {
      my @results;
      $self->_log({NAME => $logger->{NAME},
           ACTION => 'RPC',
           TIME => time(),
           DETAILS => join("|",map {$_->{NAME}} @{$logger->{SERVERS}}),
           STATE => 'a'});
      if (scalar(@{$logger->{SERVERS}})) {
    sigprocmask(SIG_BLOCK,$full_set);
    
    foreach my $server (@{$logger->{SERVERS}}) {
      unless (ref($server)) {
        $args = $server;
        next;
      }
      my @args;
      if ($args) {
        no strict 'refs';
        unless (defined $__arg_sub{$args}) {
          eval <<ECODE;
\$__arg_sub{qq($args)} = sub {
  $self->{CLVAR_CODE}
  $args
};
ECODE
            }
        @args = &{$__arg_sub{qq($args)}}($server);
        use strict 'refs';
      }
      eval {
        push(@results,$self->_make_RPC_call({SERVER => $server,
                         ARGS => \@args}));
      };
      $self->_log({NAME => $logger->{NAME},
               ACTION => 'ERROR',
               TIME => time(),
               DETAILS => $@,
               STATE => 'n'})
        if $@;
    }
    $self->_log({NAME => $logger->{NAME},
             ACTION => 'PROCESS',
             TIME => time(),
             DETAILS => "$logger->{NAME}_Code",
             STATE => 'p'});
    eval {
      &{"Enigo::Products::Quetl::Loggers::$logger->{NAME}_Code"}
        (@results);
    };
        print STDERR $@ if $@;
    $self->_log({NAME => $logger->{NAME},
             ACTION => 'ERROR',
             TIME => time(),
             DETAILS => $@,
             STATE => 'n'})
      if $@;

    sigprocmask(SIG_UNBLOCK,$full_set);

    $self->_log({NAME => $logger->{NAME},
             ACTION => 'RUN',
             TIME => time(),
             DETAILS => '',
             STATE => 'r'});
      } else {
    $self->_log({NAME => $logger->{NAME},
             ACTION => 'PROCESS',
             TIME => time(),
             DETAILS => "$logger->{NAME}_Code",
             STATE => 'p'});

    sigprocmask(SIG_BLOCK,$full_set);

    eval {
      no strict 'refs';
      &{"Enigo::Products::Quetl::Loggers::$logger->{NAME}_Code"}();
      use strict 'refs';
    };
        print STDERR $@ if $@;
    $self->_log({NAME => $logger->{NAME},
             ACTION => 'ERROR',
             TIME => time(),
             DETAILS => $@,
             STATE => 'n'})
      if $@;

    sigprocmask(SIG_UNBLOCK,$full_set);

    $self->_log({NAME => $logger->{NAME},
             ACTION => 'RUN',
             TIME => time(),
             DETAILS => '',
             STATE => 'r'});
      }

      $self->{DISPATCHER}->log(level => 'error',
                   message => "$@\nin Enigo::Products::Quetl::Loggers::$logger->{NAME}_Code\n")
    if $@;
    }
  }
  _exit();
}


sub _log {
  my $self = shift;
  my ($param) = paramCheck([ NAME => _pc_name,
                 ACTION => _pc_action_o,
                 DETAILS => _pc_details_o,
                             TIME => 'IO',
                 STATE => _pc_state_o],@_);

    (tied @Enigo::Products::Quetl::message_queue)->shlock;
    $Enigo::Products::Quetl::message_queue
      [$#Enigo::Products::Quetl::message_queue + 1] =
    freeze({NAME => $param->{NAME},
        ACTION => $param->{ACTION},
        TIME => time(),
                PID => $$,
        DETAILS => $param->{DETAILS},
        STATE => $param->{STATE}});
    (tied @Enigo::Products::Quetl::message_queue)->shunlock;
}


sub _initialize_shared_memory_for_parent {
  my ($self) = shift;

  my $prefix = join('',pack('cc',$self->{PPID}));
  #First, tie into the shared memory segment that contains the
  #message queue.
  my $t = tie(@Enigo::Products::Quetl::message_queue,
          'IPC::Shareable',$prefix . 'gq',{create => 1,
                           destroy => 1,
                           size => 131072});
  $t->shlock;
  @Enigo::Products::Quetl::message_queue = ('NULL');
  $t->shunlock;

  #Next, make a second shared variable that contains a mapping of
  #child PID to the logger that the child is running.
  tie(%Enigo::Products::Quetl::ptp,
      'IPC::Shareable',$prefix . 'tp',{create => 1,
                       destroy => 1,
                       size => 131072});
  %Enigo::Products::Quetl::ptp = ();
  #And finally, tie to a third shared variable which is the
  #resurrection list -- the list of processes which have dies
  #and which need to be restarted.
  $t = tie(@Enigo::Products::Quetl::resurection_list,
       'IPC::Shareable',$prefix . 'ls',{create => 1,
                        destroy => 1,
                        size => 131072});
  $t->shlock;
  @Enigo::Products::Quetl::resurection_list = ('NULL');
  $t->shunlock;
  #serious_errors -- a time value gets pushed onto this array every
  #time a serious error -- a failure to fork, or an inability to
  #write to the database, or some other really bad thing(tm) occurs.
  #If ERROR_THRESHOLD errors occur within ERROR_INTERVAL seconds,
  #then the monitor will log a message, optionally invoke some externally
  #defined code, and then kill it's children and exit.
  $t = tie(@Enigo::Products::Quetl::serious_errors,
       'IPC::Shareable',$prefix . 'er',{create => 1,
                        destroy => 1,
                        size => 131072});
  $t->shlock;
  @Enigo::Products::Quetl::serious_errors = ('NULL');
  $t->shunlock;

  $self->{SHARED_MEMORY_IS_INITIALIZED}++;
}


sub _initialize_shared_memory_for_child {
  my ($self) = shift;

  my $prefix = join('',pack('cc',$self->{PPID}));
  sleep(2); #paranoia, just to make sure the parent has had time to
            #setup the shared memory segments first.
  #First, tie into the shared memory segment that contains the
  #message queue.
  tie(@Enigo::Products::Quetl::message_queue,
      'IPC::Shareable',$prefix . 'gq');

  #Next, make a second shared variable that contains a mapping of
  #child PID to the logger that the child is running.
  tie(%Enigo::Products::Quetl::ptp,
      'IPC::Shareable',$prefix . 'tp');

  #And finally, tie to a third shared variable which is the
  #resurrection list -- the list of processes which have dies
  #and which need to be restarted.
  tie(@Enigo::Products::Quetl::resurection_list,
      'IPC::Shareable',$prefix . 'ls');

  #serious_errors -- a time value gets pushed onto this array every
  #time a serious error -- a failure to fork, or an inability to
  #write to the database, or some other really bad thing(tm) occurs.
  #If ERROR_THRESHOLD errors occur within ERROR_INTERVAL seconds,
  #then the monitor will log a message, optionally invoke some externally
  #defined code, and then kill it's children and exit.
  tie(@Enigo::Products::Quetl::serious_errors,
      'IPC::Shareable',$prefix . 'er');

  $self->{SHARED_MEMORY_IS_INITIALIZED}++;
}


sub _shared_memory_is_initialized {
  my ($self) = shift;

  return $self->{SHARED_MEMORY_IS_INITIALIZED};
}



sub _log_state {
  my ($self) = shift;
  my ($param) = paramCheck([ NAME => _pc_name,
                 ACTION => _pc_action_o,
                 TIME => _pc_time_o,
                             PID => 'N',
                 DETAILS => _pc_details_o,
                 STATE => _pc_state_o],@_);

  $param->{TIME} = time() unless defined($param->{TIME});
  if (defined($param->{DETAILS})) {
    $param->{ACTION} = 'info' unless defined($param->{ACTION});
    eval {
      $self->{SQL}->insert(<<ESQL);
INSERT into details (name,action,time,details)
VALUES ('$param->{NAME}','$param->{ACTION}','$param->{TIME}',
        '$param->{DETAILS}')
ESQL
    };
    push(@{$Enigo::Products::Quetl::serious_errors},
     time())
      if $@;
  }

  #This needs to go into some documentation someplace, but the states
  #that are currently defined are:
  #  s : sleeping
  #  r : running
  #  a : accessing a server
  #  l : logging
  #  p : running processing code
  #  n : general information notice
  #  e : "Danger, Will Robinson!  Danger!"  An error of some sort.
  #  d : dead
  if (defined($param->{STATE}) and $param->{NAME} !~ /^\d*$/) {
    $self->{SQL}->delete(<<ESQL);
DELETE from status where name = '$param->{NAME}'
ESQL
    $self->{SQL}->insert(<<ESQL);
INSERT into status (name,time,status,pid)
VALUES ('$param->{NAME}','$param->{TIME}','$param->{STATE}','$param->{PID}')
ESQL
  }
}


sub _make_RPC_call {
  my ($self) = shift;
  my ($param) = paramCheck([SERVER => 'HR',
                SERVICE => ['U',undef],
                ARGS => 'ARO'],@_);
  my $server = $param->{SERVER};
  my $client;
  my $cipher;
  if (defined($server->{ENCRYPTION_ALGORITHM}) and
      !defined($self->{CIPHERS}->
           {$server->{ENCRYPTION_ALGORITHM}}->
           {$server->{ENCRYPTION_KEY}})) {
    $self->{CIPHERS}->
      {$server->{ENCRYPTION_ALGORITHM}}->
    {$server->{ENCRYPTION_KEY}} = Crypt::CBC->new($server->{ENCRYPTION_KEY},
                              $server->{ENCRYPTION_ALGORITHM});
  } else {
    $cipher = $self->{CIPHERS}->
      {$server->{ENCRYPTION_ALGORITHM}}->
    {$server->{ENCRYPTION_KEY}};
  }

  try {
    $client = $self->_get_client_connection
      ({SERVER => $server->{ADDRESS},
    PORT => $server->{PORT},
    USER => $server->{USER},
    PASSWORD => $server->{PASSWORD},
    VERSION => $server->{VERSION},
    COMPRESSION => undef,
    MAXMESSAGE => $server->{MAXMESSAGE},
    TIMEOUT => $server->{TIMEOUT},
    CIPHER => $cipher});
  } catch Enigo::Common::Exception::IO::Net with {
    my $exception = shift;
    $self->{DISPATCHER}->log(level => 'error',
                 message => $exception->stringify);
    return undef;
  };

  my $service = defined $param->{SERVICE} ? $param->{SERVICE} : $server->{SERVICE};

  return $client->Call({SERVICE => $service,
                USER => $server->{USER},
                DATA => $param->{ARGS}});
}


sub _logger_make_RPC_call {
  return _make_RPC_call($Enigo::Processes::self,@_);
}


sub _send_mail {
  my ($self) = shift;
  my ($param) = paramCheck([ SUBJECT => 'U',
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
}


sub _logger_send_mail {
  return _send_mail($Enigo::Processes::self,@_);
}



sub _get_client_connection {
  my ($self) = shift;
  my ($param) = paramCheck([SERVER => _pc_server,
                PORT => _pc_port,
                USER => _pc_user,
                PASSWORD => _pc_password,
                VERSION => _pc_version,
                COMPRESSION => _pc_compression,
                MAXMESSAGE => _pc_maxmessage,
                TIMEOUT => _pc_timeout,
                CIPHER => 'UO'],@_);

  my $connection;
  eval {
    $connection = Enigo::Products::Quetl::Client->new
      (peeraddr => $param->{SERVER},
       peerport => $param->{PORT},
       user => $param->{USER},
       password => $param->{PASSWORD},
       maxmessage => $param->{MAXMESSAGE},
       cipher => $param->{CIPHER},
       application => 'Enigo::Products::RPCServer::Services',
       version => $param->{VERSION});
  };
  throw Enigo::Common::Exception::IO::Net::CouldNotConnect
    ({ADDRESS => $param->{SERVER},
      PORT => $param->{PORT}})
      if $@;

  return $connection;
}


sub _sig_CHLD_handler {
  my $child = _is_dead();
  _pray_for_resurection($child);

  $SIG{CHLD} = \&_sig_CHLD_handler;

  sub _is_dead {
    #Return the PID of the dead child.
    my $kid = waitpid(-1,0);
    return $kid;
  }

  sub _pray_for_resurection {
    my $dead_child = shift;

    #Lookup which logger the dead child was responsible for, and
    #then push that logger onto
    #@Enigo::Products::Quetl::resurection_list

    push(@Enigo::Products::Quetl::resurection_list,
     $Enigo::Products::Quetl::ptp
     {$dead_child});
    delete $Enigo::Products::Quetl::ptp
      {$dead_child};
    return undef;
  }

  return undef;
}


#Kill all of the children.  We just want to make explicitly sure that
#they do go away.
sub _cleanup_and_exit {
  my $time = POSIX::asctime(localtime(time));
  chomp($time);
  $Enigo::Products::Quetl::Dispatcher->log
    (level => 'info',
     message => "$$: Parent received a fatal signal at $time; cleaning up children.\n");

#  $SIG{CHLD} = 'DEFAULT';
#  $SIG{INT} = 'DEFAULT';
#  $SIG{QUIT} = 'DEFAULT';
#  $SIG{TERM}= 'DEFAULT';
#  $SIG{HUP} = 'DEFAULT';

#  my $full_set = POSIX::SigSet->new(SIGHUP,
#                   SIGTERM,
#                   SIGQUIT,
#                   SIGINT,
#                   SIGCHLD);
#  sigprocmask(SIG_UNBLOCK,$full_set);

  kill 15,(keys %Enigo::Products::Quetl::ptp);
  my $kid;
  do {
    $kid = waitpid(-1,&WNOHANG);
  } until $kid == -1;
  (tied @Enigo::Products::Quetl::message_queue)->shunlock;
  $Enigo::Products::Quetl::self->_handle_message_queue();

  (tied @Enigo::Products::Quetl::serious_errors)->shunlock;
  (tied @Enigo::Products::Quetl::resurection_list)->shunlock;
  (tied @Enigo::Products::Quetl::message_queue)->shunlock;

  exit();
}


sub _reinitialize {
  my $time = POSIX::asctime(localtime(time));
  chomp($time);
  $Enigo::Products::Quetl::Dispatcher->log
    (level => 'info',
     message => "$$: Parent received a HUP at $time; cleaning up children.\n");
#  my $full_set = POSIX::SigSet->new(SIGHUP,
#                   SIGTERM,
#                   SIGQUIT,
#                   SIGINT,
#                   SIGCHLD);
#  sigprocmask(SIG_UNBLOCK,$full_set);

#  $SIG{CHLD} = 'DEFAULT';
#  $SIG{INT} = 'DEFAULT';
#  $SIG{QUIT} = 'DEFAULT';
#  $SIG{TERM}= 'DEFAULT';
#  $SIG{HUP} = 'DEFAULT';

  kill 15,(keys %Enigo::Products::Quetl::ptp);
  my $kid;
  do {
    $kid = waitpid(-1,&WNOHANG);
  } until $kid == -1;
  (tied @Enigo::Products::Quetl::message_queue)->shunlock;
  $Enigo::Products::Quetl::self->_handle_message_queue();

  (tied @Enigo::Products::Quetl::serious_errors)->shunlock;
  (tied @Enigo::Products::Quetl::resurection_list)->shunlock;
  (tied @Enigo::Products::Quetl::message_queue)->shunlock;
  exec($0,@ARGV);
  exit();
}


#The children will issue a last gasp before dying in order to attempt
#to log any error messages that accompany the death.
sub _last_gasp {
print STDERR "$$ GASP!\n";
  $Enigo::Products::Quetl::self->_log({NAME => $$,
                       ACTION => 'KILLED',
                       TIME => time(),
                       DETAILS => "$! : $@",
                       STATE => 'd'});

  Enigo::Common::Override->restore('exit');
  exit();
  die();
}


sub _exit {
  _parting_speech();
  exit();
}


#If a child _exit()s, it'll issue a log message before it goes away
#to record the fact that it is exiting instead of dying.
sub _parting_speech {
print STDERR "Parting is such sweet sorrow.\n";
  my $full_set = POSIX::SigSet->new(SIGHUP,
                    SIGTERM,
                    SIGQUIT,
                    SIGINT,
                    SIGCHLD);
  sigprocmask(SIG_UNBLOCK,$full_set);

  $SIG{CHLD} = 'DEFAULT';
  $SIG{INT} = 'DEFAULT';
  $SIG{QUIT} = 'DEFAULT';
  $SIG{TERM}= 'DEFAULT';
  $SIG{HUP} = 'DEFAULT';

  $Enigo::Products::Quetl::self->_log({NAME => $$,
                       ACTION => 'EXITING',
                       TIME => time(),
                       DETAILS => '',
                       STATE => 'd'});

}

sub breakpoint {print "breakpoint\n";}
1;
