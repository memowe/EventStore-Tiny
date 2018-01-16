use 5.010001;

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'EventSourcing-Tiny',
    VERSION_FROM        => 'lib/EventSourcing/Tiny.pm',
    ABSTRACT            => 'A minimal event sourcing framework.',
    AUTHOR              => 'Mirko Westermeier <mirko@westermeier.de>',
    LICENSE             => 'mit',
    META_MERGE          => {
        resources   => {
            bugtracker  => 'http://github.com/memowe/EventSourcing-Tiny/issues',
            repository  => 'http://github.com/memowe/EventSourcing-Tiny',
        },
    },
    MIN_PERL_VERSION    => '5.10.1',
    PREREQ_PM           => {
        'Mo' => '0.38',
    },
    test                => {TESTS => 't/*.t'}
);
