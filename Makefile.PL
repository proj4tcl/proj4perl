use v5.36;
use Inline::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Proj',
    VERSION_FROM      => 'lib/Proj.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Proj.pm', # retrieve abstract from module
    AUTHOR            => 'A. U. Thor <peter@nonet>',
    #LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #https://metacpan.org/pod/Module::Build::API
    CONFIGURE_REQUIRES => {
        'Inline::MakeMaker' => 0.45,
        'ExtUtils::MakeMaker' => 6.52,
    },
);
