#!/usr/bin/perl
#
#   Perl Makefile for pafd
#
#   Invoke with 'perl Makefile.PL'
#
#   See ExtUtils::MakeMaker (3) for more information on how to influence
#    the contents of the Makefile that is written
#

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'PAFd',
    VERSION_FROM      => 'lib/PAF/Server.pm',
    AUTHOR            => 'Guillaume Blairon <g@yom.be>',
    EXE_FILES         => ['pafd'],
    PREREQ_PM         => {
        'FCGI::Async'   => '0.20',
        'File::Find'    => 0,
        'Getopt::Long'  => 0,
        'IO::Async'     => '0.28',
        'IO::Socket'    => '1.05',
    },
);
