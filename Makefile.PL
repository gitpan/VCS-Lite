use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME		=> 'VCS::Lite',
    VERSION_FROM	=> 'lib/VCS/Lite.pm', 
    PREREQ_PM		=> {Algorithm::Diff => 1.13}, 
    ABSTRACT_FROM	=> 'lib/VCS/Lite.pm', 
    AUTHOR     		=> 'Ivor Williams <IVORW@cpan.org>',
    EXE_FILES		=> [qw( 
    	scripts/vldiff scripts/vlpatch scripts/vlmerge)],
);
