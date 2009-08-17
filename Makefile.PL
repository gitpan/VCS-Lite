use ExtUtils::MakeMaker;

WriteMakefile(
    NAME		    => 'VCS::Lite',
    VERSION_FROM	=> 'lib/VCS/Lite.pm', 
    PREREQ_PM		=> {
        Algorithm::Diff => 1.13,
        Carp            => 0,

        Getopt::Long    => 0        # required by installed scripts
    }, 
    ABSTRACT_FROM	=> 'lib/VCS/Lite.pm', 
    AUTHOR     		=> 'Barbie <BARBIE@cpan.org>',
    EXE_FILES		=> [qw( 
    	scripts/vldiff scripts/vlpatch scripts/vlmerge)],
	NO_META		=> 1,
);
