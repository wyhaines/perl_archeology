use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME	=> 'DBD::SQLite',
    AUTHOR      => 'Kirk Haines',
    ABSTRACT    => 'DBI driver for the SQLite database; requires the sqlite package',
    INSTALLMAN1DIR => '/opt/man/man1',
    INSTALLMAN3DIR => '/opt/man/man3',
    PREFIX      => '/opt',
    VERSION_FROM => 'SQLite.pm', # finds $VERSION
);
