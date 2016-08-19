use Inline::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteInlineMakefile(
    NAME	=> 'sqlite',
    AUTHOR      => 'Kirk Haines',
    ABSTRACT    => 'Low level Perl interface to the SQLite library.',
    INSTALLMAN1DIR => '/opt/man/man1',
    INSTALLMAN3DIR => '/opt/man/man3',
    PREFIX      => '/opt',
    VERSION_FROM => 'sqlite.pm', # finds $VERSION
);
