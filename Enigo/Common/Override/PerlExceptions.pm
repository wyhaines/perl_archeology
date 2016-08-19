#!/usr/bin/perl -wc
# 
######################################################################
##### Header
######################################################################
=pod

=head1 FILE_NAME: PerlExceptions.pm

=head1 Enigo::Common::Override::PerlExceptions;

I<REVISION: 1.1.2.2>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: 22:53 31 OCT 2000>

=head1 PURPOSE:

This package overrides specific, requested builtins with versions that
throw exceptions instead of their usual die() semantics.

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

It is unlikely that all of these currently have exception throwing
version that have been written.  If in doubt regarding whether a
specific builtin has an exception throwing version, look in
Enigo::Common::Override::PerlExceptions for a package for the function
that you are curious about.

=head1 TODO:

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

package Enigo::Common::Override::PerlExceptions;

use 5.00503;
use strict;

require Enigo::Common::Override;
@Enigo::Common::Override::PerlExceptionsISA = qw(Enigo::Common::Override);


######################################################################
##### Method: import
######################################################################

=pod

=head2 METHOD_NAME: import

I<AUTHOR: Kirk Haines>

I<DATE_CREATED: 2000 Aug 02>

=head2 PURPOSE:

Overrides builtin functions with versions that throw exceptions.

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

  use Enigo::Common::Override::PerlExceptions qw(fork die);

  use Enigo::Common::Override {fork => [qw(bif foo::bar baz)],
             die => [qw(bif baz)]};

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
        push(@Enigo::Common::Override::PerlExceptions::EXPORT_OK,$function);

    my $ecode = <<ECODE;
require Enigo::Common::Override::PerlExceptions::$function;
\$Enigo::Common::Override::PerlExceptions::overrides{\$function} =
  \\&Enigo::Common::Override::PerlExceptions::${function}::${function};
ECODE
    eval($ecode);
    throw Enigo::Common::Exception::IO::File::NotFound
      ("Enigo::Common::Override::PerlExceptions::$function")
        if $@;
    no strict qw(refs);

    eval <<ECODE;
*{"$function"} = sub
  {
    &{\$Enigo::Common::Override::PerlExceptions::Destination{"$function"}}(\@_);
  }
ECODE
        use strict qw(refs);

        unless ($Enigo::Common::Override::DoesNotWantArgs{$function})
          {
        eval "\$Enigo::Common::Override::PerlExceptions::Destination{$function} = sub {CORE::$function(\@_)};";
      }
    else
      {
        eval "\$Enigo::Common::Override::PerlExceptions::Destination{$function} = sub {CORE::$function()};"; 
      }

    foreach my $namespace (@{$namespace{$function}})
      {
        no strict qw(refs);
        *{"${namespace}::${function}"} = *{"$function"};
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

Performs the overriding of a builtin with an exception throwing
version.

=head2 ARGUMENTS:

Expects to be called as a class method, and expects arguments to
be a list of builtins to override.  Any builtin that is to
be overridden B<must> have been listed in the C<use> statement.

=head2 RETURNS:

undef

=head2 EXAMPLE:

  Enigo::Common::Override::PerlExceptions->override(qw(exit fork));

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

    foreach my $function (@_)
      {
    $Enigo::Common::Override::PerlExceptions::Destination
      {"$function"} =
        $Enigo::Common::Override::PerlExceptions::overrides
          {"$function"};
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
        eval "\$Enigo::Common::Override::PerlExceptions::Destination{$function} = sub {CORE::$function(\@_)};";
      }
    else
      {
        eval "\$Enigo::Common::Override::PerlExceptions::Destination{$function} = sub {CORE::$function()};"; 
      }
      }
  }


1;
