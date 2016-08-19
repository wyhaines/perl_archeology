A Few General Module Guidelines

  Version: $Revision: 1.1.1.1 $

    If your module is just straight Perl and doesn't require any special
    compilation steps or preperation steps before it can be installed onto a
    machine and then used, put it in Enigo/.  Look at the
    Enigo/Enigo_README.pod file for more information.

    If you module requires some sort of preperation, or is designed to be a
    standalone, self contained, CPAN style distributable module, read on.

    All modules that are designed to be CPAN distributable (whether there is
    actually an intent to place them onto CPAN or not), should be homed at
    this level of the directory tree.  By CPAN distributable, I mean a self
    contained unit that is built, generally, with a:

    perl Makefile.PL
    make
    make test
    make install
    sequence of actions.  These modules should be designed to install into
    /opt/enigo/lib/perl5 unless they really are intended for CPAN
    distribution, in which case they should conform to Perl standards with
    regard to installation location.

    Take a look at Enigo/lib.pm for a solution to the problem of how to get
    programs to use the correct architecture dependent and independent
    subdirectories out of /opt/enigo/lib/perl5 when a module is built using
    multiple versions of Perl.

