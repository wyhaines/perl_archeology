#!/usr/bin/perl -wc
# 
######################################################################
##### Header
######################################################################
=pod

=head1 FILE_NAME: Override.pm

=head1 Enigo::Common::Override

I<REVISION: $Revision: 1.1.1.1 $>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: $Date: 2001/12/17 02:28:37 $>

=head1 PURPOSE:

This is a dangerous package.

Use it to override Perl's builtin functions with your own code, but think
very carefully about the implications of such an action before doing it.

Also, this module is not at all friendly toward other namespaces.  It
lets you pollute them at will in order to override builtins on the assumption
that if you really want to override a builtin, you know what you are doing.

One usage might be to trap calls to C<exit> so that some special handling
can be done, or to override a builtin such a C<time> with one that reveals
some sort of enhanced functionality.  This module introduces a layer of
redirection to any function that it is told to enable overrideability
for, so don't use this unless you are very sure that the best/only way
for the software to work is to override a function.

As of Perl 5.005_03, the following can be overridden:

CORE, __FILE__, __LINE__, __PACKAGE__, abs, accept, alarm, and, atan2,
bind, binmode, bless, caller, chdir, chmod, chown, chr, chroot, close,
closedir, cmp, connect, continue, cos, crypt, dbmclose, dbmopen, die, dump,
endgrent, endhostent, endnetent, endprotoent, endpwent, endservent, eof,
eq, exec, exit, exp, fcntl, fileno, flock, fork, formline, ge, ge, getc,
getgrent, getgrgid, getgrnam, gethostbyaddr, gethostbyname, gethostent,
getlogin, getnetbyaddr, getnetbyname, getnetent, getpeername, getpgrp,
getppid, getpriority, getprotobyname, getprotobynumber, getprotoent,
getpwent, getpwnam, getpwuid, getservbyname, getservbyport, getservent,
getsockname, getsockopt, gmtime, gt, gt, hex, index, int, ioctl, join,
kill, lc, lcfirst, le, length, link, listen, localtime, lock, log, lstat,
lt, mkdir, msgctl, msgget, msgrcv, msgsnd, ne, not, oct, open, opendir, or,
ord, pack, pipe, quotemeta, rand, read, readdir, readline, readlink,
readpipe, recv, ref, rename, require, reset, reverse, rewinddir, rindex,
rmdir, seek, seekdir, select, semctl, semget, semop, send, setgrent,
sethostent, setnetent, setpgrp, setpriority, setprotoent, setpwent,
setservent, setsockopt, shmctl, shmget, shmread, shmwrite, shutdown, sin,
sleep, socket, socketpair, sprintf, sqrt, srand, stat, substr, symlink,
syscall, sysopen, sysread, sysseek, system, syswrite, tell, telldir, time,
times, truncate, uc, ucfirst, umask, unlink, unpack, utime, values, vec,
wait, waitpid, wantarray, warn, write, x, xor

If this frightens you, good.  It should.

=head1 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

package Enigo::Common::Override;

use 5.00503;
use strict;

require Exporter;
@Enigo::Common::Override::ISA = qw(Exporter);

#Some of the perl builtins don't take any arguments.  These need to
#be known so that the code doesn't attempt to pass @_ to them.
#They are:
%Enigo::Common::Override::DoesNotWantArgs = (endgrent => 1,
                      endpwent => 1,
                      endnetent => 1,
                      endservent => 1,
                      endhostent => 1,
                      endprotoent => 1,
                      fork => 1,
                      getppid => 1,
                      getpwent => 1,
                      getprotoent => 1,
                      gethostent => 1,
                      getnetent => 1,
                      getservent => 1,
                      getgrent => 1,
                      getlogin => 1,
                      setpwent => 1,
                      setgrent => 1,
                      time => 1,
                      times => 1,
                      wait => 1,
                      wantarray => 1);

######################################################################
##### Method: import
######################################################################

=pod

=head2 METHOD_NAME: import

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 2000 June 13>

=head2 PURPOSE:

Provides a mechanism with which to override Perl builtin functions.

=head2 ARGUMENTS:

Expects a list of builtin functions for which to enable the ability
to override them.  By default, this will just override the calls
to the specified functions within the package that issued the
C<use Enigo::Common::Override> (the calling package).  If there is a need
to override the calls to certain builtins for code running in other
namespaces, that can be done via a more complex set of arguments in
the C<use> command.

To override a builtin over multiple namespaces, pass into the
use command a hash reference with the functions to override as
the keys.  The value for each key will be an array reference
containing the names of the namespaces to setup overrides in.  The
calling package is _not_ automatically setup to be overridden
when using this syntax; it must be explicitly specified.

Use the C<Enigo::Common::Override::override()> method
to actually override a function, and the
C<Enigo::Common::Override::restore()> method to restore the original
behavior to a previously overriden function.

=head2 RETURNS:

undef

=head2 EXAMPLE:

  use Enigo::Common::Override qw(time exit);

  use Enigo::Common::Override {time => [qw(bif foo::bar baz)],
                            exit => [qw(bif baz)]};

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################


sub import
  {
    my $self = shift;
    my @functions;
    my %namespace;
    if (ref($_[0]) eq 'HASH')
      {
    @functions = keys(%{$_[0]});
    $namespace{$_} = $_[0]->{$_} foreach (@functions);
      }
    else
      {
    @functions = @_;
    $namespace{$_} = [scalar(caller())] foreach (@functions);
      }
    
    foreach my $function (@functions)
      {
        push(@Enigo::Common::Override::EXPORT_OK,$function);
    
    no strict qw(refs);
    eval <<ECODE;
*{\$function} = sub
  {
    &{\$Enigo::Common::Override::Destination{$function}}(\@_);
  }
ECODE
        use strict qw(refs);
    
        unless ($Enigo::Common::Override::DoesNotWantArgs{$function})
          {
        eval "\$Enigo::Common::Override::Destination{$function} = sub {CORE::$function(\@_)};";
      }
    else
      {
        eval "\$Enigo::Common::Override::Destination{$function} = sub {CORE::$function()};"; 
      }

    foreach my $namespace (@{$namespace{$function}})
      {
        no strict qw(refs);
        *{"${namespace}::${function}"} = *{$function};
        use strict qw(refs);
      }
      }
  }


######################################################################
##### Method: override
######################################################################

=pod

=head2 METHOD_NAME: override

I<AUTHOR: Kirk>

I<DATE_CREATED: 2000 Aug 02>

=head2 PURPOSE:

Performs the overriding of a builtin.

=head2 ARGUMENTS:

Expects to be called as a class method, and expects arguments in the
form of a hash (_not_ a hash reference) where the keys of the hash are
the builtins to override, and the values are code refs that point to
code new code for each of the builtins.

=head2 RETURNS:

undef

=head2 EXAMPLE:

  Enigo::Common::Override->override(exit => sub{return @_});

  Enigo::common::Override->override(fork => \&my_fork,
                     require => \&require_from_database);

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub override
  {
    my $self = shift;
    my %overrides = @_;

    foreach my $function (keys %overrides)
      {
    next unless (ref($overrides{$function}) eq 'CODE');

    $Enigo::Common::Override::Destination{$function} = $overrides{$function};
      }
  }


######################################################################
##### Method: restore
######################################################################

=pod

=head2 METHOD_NAME: restore

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 2000 Aug 02>

=head2 PURPOSE:

Restores the original function of an overridden builtin.

=head2 ARGUMENTS:

Expects to be called as a class method, and expects a list of
builtins to restore.

=head2 RETURNS:

undef

=head2 EXAMPLE:

  Enigo::Common::Override->restore('exit');

  Enigo::Common::Override->restore(qw(exit fork require));

=head2 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

sub restore
  {
    my $self = shift;
    
    foreach my $function (@_)
      {
        unless ($Enigo::Common::Override::DoesNotWantArgs{$function})
      {
        eval "\$Enigo::Common::Override::Destination{$function} = sub {CORE::$function(\@_)};";
      }
    else
      {
        eval "\$Enigo::Common::Override::Destination{$function} = sub {CORE::$function()};"; 
      }
      }
  }


1;
