#!perl -w

require 5.008001;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'WWW::wordpress',
    DISTNAME		 => 'www-wordpress',
    VERSION_FROM     => 'lib/WWW/wordpress.pm',
    ABSTRACT   		 => 'wordpress API interface',
    AUTHOR           => q{Daniel Torres <daniel.torres@owasp.org>},  
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.008001,
    PREREQ_PM => {
        'Moose' => 0,
        'Net::SSL' => 0,
        'LWP::UserAgent' => 0,
        'HTTP::Cookies' => 0,
        'JSON' => 0,
        'URI' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'WWW-wordpress-*' },
);
