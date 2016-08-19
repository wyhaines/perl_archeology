#!/usr/bin/perl -wc
#
######################################################################
##### Header
######################################################################

=pod

=head1 FILE_NAME: $RCSfile: Server.pm,v $

=head1 Enigo::Products::RPCServer;

I<REVISION: $Revision: 1.1.1.1 $>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: $Date: 2001/12/17 02:28:37 $>

=head1 PURPOSE:

Herein lies the structure of the RPCServer.

=head1 TODO:

=over 4

=item XML-RPC

Sometime down the road, converting to XML-RPC would be a nice
thing to do.

=back

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

package Enigo::Products::RPCServer::Server;

use strict;
use vars qw($AUTOLOAD $VERSION @ISA);
use Enigo::Products::RPCServer::RPCServer;
use Getopt::EvaP;
use Enigo::Common::Log::Dispatch;
use Enigo::Common::Log::Dispatch::File;
use Enigo::Common::Log::Dispatch::Screen;
use Enigo::Common::Log::Dispatch::Callback;
use Enigo::Common::Log::Dispatch::Email::MailSendmail;
use Enigo::Products::RPCServer::Server::Service;
use Enigo::Products::RPCServer::Server::Client;
use Enigo::Products::RPCServer::Server::User;
use Enigo::Common::MethodHash;

use Proc::Daemon;
use Crypt::CBC;
use LWP::UserAgent;
use XML::Parser::PerlSAX;
use XML::Grove;
use XML::Grove::Builder;
use Data::Dumper;
use POSIX qw(:signal_h :sys_wait_h);

use Enigo::Common::Filter qw(RPCServer);
use Enigo::Common::Exception qw(:IO :eval);
use Enigo::Common::Config;
use Enigo::Common::Override {exit => [qw(Enigo::Monitor)]};
use Enigo::Common::ParamCheck qw(paramCheck);
use Enigo::Common::SQL::SQL;

$VERSION = '$Revision: 1.1.1.1 $' =~ /\$Revision:\s+([^\s]+)/; #'
@ISA = qw(Enigo::Common::MethodHash);

use vars qw($AUTOLOAD);

$SIG{'__WARN__'} = sub {};


######################################################################
##### Constructor: new
######################################################################

=pod

=head2 CONSTRUCTOR_NAME: new

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 01 Nov 2001>

=head2 PURPOSE:

Returns a blessed hash reference.

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
  $self->_init(@_);
  $Enigo::Products::RPCServer::Server::self = $self;
  return $self;
}


######################################################################
##### Method: _init
######################################################################

=pod

=head2 METHOD_NAME: _init

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 1 Nov 2001>

=head2 PURPOSE:

Initializes a new Server object.

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

sub _init {
  my ($self) = shift;
  my ($param) = shift;

  $self->{CONFIG_CATALOG} = $param->{CONFIG_CATALOG};
  $self->{CONFIG_LABEL} = $param->{CONFIG};
  $self->_initConfig();

  $self->_processOptions();

  $self->_readConfig();

  $self->_initDatabase();

  $self->_initXML();

  $self->_initUA();

  $self->_initDispatcher();


  my $time = POSIX::asctime(localtime(time));
  chomp($time);
  $self->{DISPATCHER}->log(level => 'info',
               message => "$$: Starting RPCServer at $time.\n");

  $self->{SERVICES} = $self->_initServices();

  $self->{DISPATCHER}->log(level => 'debug',
               message => "$$: Initialization completed.\n");
}


sub _initConfig {
  my ($self) = shift;
  $self->{CONFIG} = new Enigo::Common::Config();
  $self->{CONFIG}->parse($self->{CONFIG_CATALOG});
  $self->{CONFIG}->read($self->{CONFIG_LABEL});
}


sub _readConfig {
  my ($self) = shift;

  my $CONFIG = $self->{CONFIG};
  $self->DEBUG_LOG($CONFIG->debug_log)
    ->INFO_LOG($CONFIG->info_log)
    ->MINOR_LOG($CONFIG->minor_log)
    ->MAJOR_LOG($CONFIG->major_log)
    ->CRITICAL_LOG($CONFIG->critical_log)
    ->PIDFILE($CONFIG->pidfile)
    ->DAEMON($CONFIG->daemon)
    ->PORT($CONFIG->port)
    ->SERVICE_INDEX($CONFIG->service_index)
    ->DSN($CONFIG->DSN)
    ->USER($CONFIG->USER)
    ->AUTH($CONFIG->AUTH);

  eval(join('',
        '$self->{AUTOLOAD_INC} = [qw(',
        join(' ',split(/,/,$self->{CONFIG}->get('autoload_inc'))),
        ')];'));
}


sub _initDatabase {
  my ($self) = shift;

  $self->{SQL} = Enigo::Common::SQL::SQL->new({DSN => $self->{DSN},
                           USER => $self->{USER},
                           AUTH => $self->{AUTH},
                           ATTRIB => {PrintError => 0,
                              RaiseError => 1},
                           CONFIG_OBJECT => $self->{CONFIG}});
  $Enigo::Products::RPCServer::SQL = $self->{SQL};

  my $sth;
  my $dbh = $self->{SQL}->get_dbh({DSN => $self->{DSN},
                   USER => $self->{USER},
                   AUTH => $self->{AUTH}},
                   ATTRIB => {PrintError => 0,
                          RaiseError => 1});
  $dbh->{PrintError} = 0;
  $dbh->{RaiseError} = 1;

  eval {
    $sth = $dbh->prepare('SELECT path FROM seen');
    $sth->execute();
  };

  if ($@) {
    eval {
      $sth = $dbh->prepare(<<ESQL);
CREATE TABLE seen (path CHAR(200),
                   confdate CHAR(14),
                   confpos CHAR(14),
                   trandate CHAR(14),
                   tranpos CHAR(14),
                   length char(14),
                   hash char(22),
                   status char(1),
                   retrycount char(2))
ESQL
      $sth->execute();

      $sth = $dbh->prepare(<<ESQL);
CREATE INDEX path_idx ON seen (path)
ESQL
      $sth->execute();
    };
  }

  eval {
    $sth = $dbh->prepare('SELECT service from history');
    $sth->execute();
  };

  if ($@) {
    eval {
      $sth = $dbh->prepare(<<ESQL);
CREATE TABLE history (service CHAR(200),
                      date CHAR(14),
                      path CHAR(200),
                      bytes CHAR(14),
                      lspos CHAR(14),
                      size CHAR(14),
                      hash CHAR(22),
                      action CHAR(1))
ESQL
      $sth->execute();
    };
  }
}


sub _initXML {
  my ($self) = shift;


  $self->{BUILDER} = new XML::Grove::Builder();
  $self->{PARSER} = new XML::Parser::PerlSAX(Handler => $self->{BUILDER});
}


sub _initUA {
  my ($self) = shift;

  $self->{UA} = new LWP::UserAgent;
  $self->{UA}->agent
    ("EnigoRPCServer-$VERSION/"
     . $self->{UA}->agent());
}


sub _initDispatcher {
  my ($self) = shift;

  $self->{DISPATCHER} = new Enigo::Common::Log::Dispatch();

  #####
  #// We're putting the dispatcher into here so that it can be accessed
  #// outside of a method.
  #####
  $Enigo::Products::RPCServer::Server::Dispatcher = $self->{DISPATCHER};

  #####
  #// The assumption here is that all logging destinations are completely
  #// configurable.  There will be 5 lines in the configuration file,
  #// debug_log,info_log,minor_log,major_log,critical_log, that will
  #// provide the details for each level of logging.  These details
  #// will be provided as a comma seperated list consisting of a
  #// destination type (which, when prefixed with
  #// 'Enigo::Common::Log::Dispatch' should map to a class implimenting
  #// that destination type) followed by a semicolon (;), followed by a
  #// list of key = value pairs, vertical bar seperated, that provides
  #// the initialization information for that logging destination
  #// For example:
  #//
  #//   debug_log=screen;min_level=debug|max_level=debug|stderr=1,
  #//             file;min_level-debug|max_level=debug|filename=/tmp/dbglog
  #//
  #// Note that in the actual config file all of that would have to be
  #// on a single line.
  #####
  foreach my $data ([debug => $self->DEBUG_LOGDATA],
            [info => $self->INFO_LOGDATA],
            [minor => $self->MINOR_LOGDATA],
            [major => $self->MAJOR_LOGDATA],
            [critical => $self->CRITICAL_LOGDATA]) {
    my $level = $data->[0];
    my @destinations = split(/,/,$data->[1]);

    foreach my $destination (@destinations) {
      my ($type,$keys) = split(/;/,$destination,2);
      my @keys;
      foreach my $keyval (split(/\|/,$keys)) {
    my ($key,$value) = $keyval =~ m{\s*(\w+)\s*=\s*(.*)\s*$ };
    push @keys,$key,$value;
      }

      $type = "Enigo::Common::Log::Dispatch::$type";
      $self->{DISPATCHER}->add($type->new(@keys));
    }
  }
}


sub _processOptions {
  my ($self) = shift;
  my @PDT = split("\n",<<'EPDT');
PDT RPCserver
  loglevel, l: string
  daemon, d: switch
  version, v: switch
  logfile, f: string
  port, p: string
  validate, a: switch
PDTEND optional_file_list
EPDT
    my @MM = split("\n",<<'EMM');
RPCserver [-l|-loglevel 0-2][-d|-daemon] [-v|-version]
          [-f|-logfile FILENAME] [-p|-port PORTNUMBER]
          [-a|-validate]
.loglevel
  The logging level of the server.  0 is very basic loggin, while 2 is
  extensive logging.  The server logs to a dedicated logfile which defaults
  to /var/RPCServer/log unless overridden either in the configs or
  on the command line.
.daemon
  Tells RPCServer whether it should fork itself off as a daemon or not.
  This defaults to on.
.version
  The version number of RPCServer.
.logfile
  This is the path to the file that RPCServer should log to.
.port
  This is the port number that the RPCServer should connect to.
.validate
  Syntax check all of the services, and then exit.  This is used
  to validate the code for the defined services without having to
  start the RPCServer daemon.
EMM
  my %opts;
  EvaP(\@PDT,\@MM,\%opts);

  if (($opts{loglevel} !~ /^[0-2]$/ and defined($opts{loglevel})) or
      (!defined $opts{loglevel} and
       $ENV{LOGLEVEL} !~ /^[0-2]$/ and
       defined $ENV{LOGLEVEL})) {
    throw Enigo::Common::Exception::General
      ({TYPE => 'BadLoglevel',
    TEXT => 'The loglevel myst be 0, 1, or 2.'}); 
  }
  if (($opts{port} !~ /^\d+$/ and defined($opts{port})) or
      (!defined $opts{port} and
       defined $ENV{PORT} and
       $ENV{PORT} =~ /^\d+$/)) {
    throw Enigo::Common::Exception::General
      ({TYPE => 'BadPortnumber',
    TEXT => "$opts{port} is not acceptable.\nThe port must be an integer number."});
  }

  $self->{LOGFILE} = $ENV{LOGFILE} if defined $ENV{LOGFILE};
  $self->{LOGLEVEL} = $ENV{LOGLEVEL} if defined $ENV{LOGLEVEL};
  $self->{DAEMON} = $ENV{DAEMON} if defined $ENV{DAEMON};
  $self->{PORT} = $ENV{PORT} if defined $ENV{PORT};
  $self->{PIDFILE} = $ENV{PIDFILE} if defined $ENV{PIDFILE};

  $self->{LOGFILE} = $opts{logfile} if defined $opts{logfile};
  $self->{LOGLEVEL} = $opts{loglevel} if defined $opts{loglevel};
  $self->{DAEMON} = $opts{daemon} if defined $opts{daemon};
  $self->{PORT} = $opts{port} if defined $opts{port};

  $self->{LOGFILE} = '/var/log/RPCServer/RPCServer.log' unless $self->{LOGFILE};
  $self->{PIDFILE} = '/var/log/RPCServer/pidfile' unless $self->{PIDFILE};
  $self->{LOGLEVEL} = 2 unless defined $self->{LOGLEVEL};
  $self->{PORT} = 4455 unless $self->{PORT};
  $self->{USER} = 'nobody' unless $self->{USER};
  $self->{GROUP} = 'nobody' unless $self->{GROUP};
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

  return undef;
}


######################################################################
##### Method: _initServices
######################################################################

=pod

=head2 METHOD_NAME: _initServices

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 06 JUN 2000>

=head2 PURPOSE:

Internal routine to read the services from their files and set
them up for invocation.  This method is not part of the public
interface to this class, but is being documented here to provide
important background information regarding service files and
how they are parsed.

=head2 ARGUMENTS:

none

=head2 RETURNS:

An array ref of services.

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

sub _initServices {
  my ($self) = shift;

  $self->{DISPATCHER}->log(level => 'debug',
               message => "$$: reading services...\n");

  Enigo::Common::Override->override(exit => sub {return @_;});

  my $services = {};
  my %fetched;
  open(FILE,$self->{SERVICE_INDEX}) || eval {
    $self->{DISPATCHER}->log
      (level => 'critical',
       message => "$$: Could not read the service_index at $self->{SERVICE_INDEX}; exiting.\n");
    throw Enigo::Common::Exception::IO::File::NotReadable
      ($self->{SERVICE_INDEX});
  };

  while (my $line = <FILE>) {
    #####
    #// Remove comments.
    #####
    $line =~ s/\#(.*)$//g if (index($line,'#') >= 0);

    #####
    #// Skip if the line is blank or just whitespace.
    #####
    next if ($line =~ /^\s*$/);

    #####
    #// Prune leading whitespace.
    #####
    $line =~ s/^\s*// if ($line =~ /^\s/);

    #####
    #// If it's not in URI format (not a very bombproof regexp to check
    #// this, I admit) assume that we want a file, and construct a
    #// file URI.
    #####
    unless ($line =~ m|^\w+:/|) {
      $line = "/$line" unless (index($line,'/') == 0);
      $line = "file:$line";
    }
    chomp($line);

    #####
    #// If it turns out we've already loaded this module,
    #// don't do it again.
    #####
    next if ($fetched{$line});

    #####
    #// Let's go get it.
    #####
    my $result = 
      $self->{UA}->request(HTTP::Request->new(GET => $line));
    next unless ($result->is_success);

    $fetched{$line}++;
    my $content = $result->content;

    #####
    #// Got it.  Make it useable and push it onto our array.
    #####
    my $parsed = $self->_parse_service($content,$line);
    $services->{$parsed->{METHOD}} = $parsed if ($parsed);
  }

  close(FILE) || eval {
    $self->{DISPATCHER}->log
      (level => 'critical',
       message => "$$: Could not close the service_index at $self->{SERVICE_INDEX}; exiting.\n");
    throw Enigo::Common::Exception::IO::File::NotCloseable
      ($self->{SERVICE_INDEX});
  };

  *Enigo::Products::RPCServer::Services::AUTOLOAD = \&_AUTOLOAD;
  return $services;
}


sub _parse_service {
  my ($self) = shift;
  my ($content) = shift;
  my ($origin) = shift;

  my $grove = $self->{PARSER}->parse(Source => {String => $content});
  my $service = Enigo::Products::RPCServer::Server::Service->new
    ({METHOD => '',
      MAXMESSAGE => 65536,
      CLIENTS => {},
      CODE => ''});
  #####
  #// Start checking the XML elements.
  #####
  foreach my $item (@{$grove->{Contents}}) {
    next unless (ref($item) !~ /XML::Grove::Characters/);

    #####
    #// Match a <service> tag.
    #####
    if (ref($item) =~ /::Element/ and $item->{Name} =~ /^service$/i) {
      #####
      #// Get the attributes.
      #####
      $service->METHOD($item->{Attributes}->{method})
    if defined $item->{Attributes}->{method};
      $service->MAXMESSAGE($item->{Attributes}->{maxmessage})
    if defined $item->{Attributes}->{maxmessage};
      #####
      #// Get the tags under the <service> tag.  Hopefully a <code> tag
      #// and at least one <client> tag.
      #####
      for my $service_item (@{$item->{Contents}}) {
    next unless (ref($service_item) !~ /XML::Grove::Characters/);
    #####
    #// Get the contents of the <code> tag.
    #####
    if (ref($service_item) =~ /::Element/ and
        $service_item->{Name} =~ /code$/i) {
      $service->CODE(join('',map{$_->{Data};}
                  @{$service_item->{Contents}}));
    }

    #####
    #// Parse a <client> tag.
    #####
    if (ref($service_item) =~ /::Element/ and
        $service_item->{Name} =~ /client$/i) {
      my $client = Enigo::Products::RPCServer::Server::Client->new
        ({MASK => '\d+\.\d+\.\d+\.\d+',
          ACCEPT => 0,
          ENCRYPTION_ALGORITHM => '',
          ENCRYPTION_KEY => '',
          USERS => {}});
      #####
      #// Get the attributes.
      #####
      $client->MASK($service_item->{Attributes}->{mask})
        if defined $service_item->{Attributes}->{mask};
      $client->ACCEPT($service_item->{Attributes}->{accept})
        if defined $service_item->{Attributes}->{accept};
      $client->ENCRYPTION_ALGORITHM
        ($service_item->{Attributes}->{encryption_algorithm})
          if defined $service_item->{Attributes}->{mask};
      $client->ENCRYPTION_KEY
        ($service_item->{Attributes}->{encryption_key})
          if defined $service_item->{Attributes}->{mask};
      #####
      #// Get any <user> tags under the <client> tag.
      #####
      for my $client_item (@{$service_item->{Contents}}) {
        next unless (ref($client_item) !~ /XML::Grove::Characters/);

        if (ref($client_item) =~ /::Element/ and
        $client_item->{Name} =~ /user$/i) {
          #####
          #// Get the attributes for the tag & push it into the client.
          #####
          $client->{USERS}->{$client_item->{Attributes}->{name}} =
        Enigo::Products::RPCServer::Server::User->new
            ({NAME => $client_item->{Attributes}->{name},
              PASSWORD => $client_item->{Attributes}->{password},
              ENCRYPTION_ALGORITHM =>
              $client_item->{Attributes}->{encryption_algorithm},
              ENCRYPTION_KEY => $client_item->{Attributes}->{encryption_key}});
        }
    
        #####
        #// Push the client into the service.
        #####
        $service->CLIENTS->{$client->MASK} = $client;
      }
    }
      }
    }
  }
  unless ($service->METHOD and $service->CODE) {
    my $time = POSIX::asctime(localtime(time));
    chomp($time);
    my $lacking = join(' and ',
               (grep {$_}
            (!$service->METHOD ? "a method name" : undef,
             !$service->CODE ? "service code" : undef)));
    $self->{DISPATCHER}->log
      (level => 'major',
       message => "$$: Vivification of the service at $origin failed at $time because the service definition lacks $lacking.\n");

    return undef;
  }

  #####
  #// Create the service subroutine (method).
  #####
  my $code = join("\n",
          "package Enigo::Products::RPCServer::Services;",
          "sub $service->{METHOD} {",
          $self->{CLVAR_CODE},
          $service->CODE,
          "};",
          "package Enigo::Products::RPCServer::Server;");

  my $time = POSIX::asctime(localtime(time));
  chomp($time);
  $self->{DISPATCHER}->log
    (level => 'debug',
     message => "$$: Filtering and creating Enigo::Products::RPCServer::Services::$service->{METHOD} at $time.\n");
  $code = Enigo::Common::Filter->filter($code);
  eval($code);
  throw Enigo::Common::Exception::Eval($code) if ($@);

  return $service;
}


sub _AUTOLOAD {
  (my $path = "$AUTOLOAD.pm") =~ s{::}{/}g;
  $Enigo::Products::RPCServer::Server::Dispatcher->log
    (level => 'debug',
     message => "$$: Attempting to autoload $AUTOLOAD\n");
  foreach my $directory (@{$Enigo::Products::RPCServer::Server::self->{AUTOLOAD_INC}}) {
    $Enigo::Products::RPCServer::Server::Dispatcher->log
      (level => 'debug',
       message => "$$: Checking $directory/$path\n");
    next unless -r "$directory/$path";

    my $code;
    {
      $Enigo::Products::RPCServer::Server::Dispatcher->log
    (level => 'debug',
     message => "$$: Autoloading $AUTOLOAD from $directory/$path\n");
      local $/;
      open(INC,"<$directory/$path") or eval {
    my $time = POSIX::asctime(localtime(time));
        chomp($time);
    $Enigo::Products::RPCServer::Server::Dispatcher->log
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
      $Enigo::Products::RPCServer::Server::Dispatcher->log
    (level => 'alert',
     message => "$$: Eval of $directory/$path failed at $time because:\n$@\n");
      throw Enigo::Common::Exception::Eval($code);
    }

    goto &$AUTOLOAD;
  }
}


sub run {
  my ($self) = shift;

  eval {
    print "Validate OK\n";
    exit();
  } if $self->{OPTS}->{validate};

  #####
  #// We need to make sure that the HUP signal is not being blocked, then setup
  #// our signal handler.
  #####
  sigprocmask(SIG_UNBLOCK,POSIX::SigSet->new(SIGHUP));
  $SIG{HUP} = \&_reinitialize;

  if ($self->{DAEMON}) {
    my $time = POSIX::asctime(localtime(time));
    chomp($time);
    $self->{DISPATCHER}->log(level => 'info',
                 message => "$$: Forking and backgrounding RPCServer at $time....\n");
    Proc::Daemon::Init();
    $time = POSIX::asctime(localtime(time));
    chomp($time);
    $self->{DISPATCHER}->log(level => 'info',
                 message => "$$: Finished forking; server daemonized at $time\n");
  }

  my $cipher = '';
  $cipher = Crypt::CBC->new($self->{ENCRYPTION_KEY},
                $self->{ENCRYPTION_ALGORITHM})
    if $self->{ENCRYPTION_ALGORITHM};

  $self->{DISPATCHER}->log(level => 'debug',
               message => "Creating new RPCServer\n");

  my $server_params = {pidfile => "$self->{PIDFILE}",
               facility => 'daemon',
               localport => $self->{PORT},
               mode => 'fork',
               logfile => 0,
               SERVICES => $self->{SERVICES},
               methods => {},
               DISPATCHER => $self->{DISPATCHER}
              };
  #####
  #// Setup the standard commands
  #####
  $server_params->{methods}->{'Enigo::Products::RPCServer'} =
    {listServices => 1};

  #####
  #// Setup the list of available services and responses.
  #####
  foreach my $service (keys(%{$self->{SERVICES}})) {
    $server_params->{methods}->{'Enigo::Products::RPCServer::Services'}->
      {$service} = 1;
  }

  my $server = Enigo::Products::RPCServer::RPCServer->new
    ($server_params);
  $self->{DISPATCHER}->log(level => 'info',
               message => "$$: Binding RPCServer\n");
  $self->{server} = $server;
  $server->Bind();
}


sub listServices {
  my ($self) = shift;

  my $list = {};
  foreach my $service (@{$self->{SERVICES}}) {
    $list->{$service->{NAME}}++;
  }

  return $list;
}


sub _reinitialize {
  #####
  #// This is cheesy, but we're going to write a little program into
  #// /tmp which will sleep for a couple of seconds and then do the restart.
  #// This should give the socket time to clear.  This is probably completely
  #// unnecessary, however.
  #####

  my $time = POSIX::asctime(localtime(time));
  chomp($time);
  $Enigo::Products::RPCServer::Server::Dispatcher->log
    (level => 'alert',
     message => "$$: HUP signal received at $time; restarting...\n");

  my $command = join(' ',
             $0,
             @ARGV,
             '&');
  open(RESTART,">/tmp/restart_RPCServer_$$.sh");
  print RESTART <<ECODE;
#!/bin/sh

sleep 3;

$command
rm -f /tmp/restart_RPCServer_$$.sh
ECODE

  close(RESTART);
  chmod 0700,"/tmp/restart_RPCServer_$$.sh";
  $Enigo::Products::RPCServer::Server::self->{server}->Close();
  $Enigo::Products::RPCServer::Server::self->{server}->Done(1);
  my $kid;
  do {
    $kid = waitpid(-1,&WNOHANG);
    select(undef,undef,undef,.05);
  } until $kid == -1;
  system("/tmp/restart_RPCServer_$$.sh&");
  exit();
}
1;
