use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'VCS::Lite',
    'VERSION_FROM'	=> 'Lite.pm', # finds $VERSION
    'PREREQ_PM'		=> {Algorithm::Diff => 1.13}, 
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Lite.pm', # retrieve abstract from module
       AUTHOR     => 'Ivor Williams <IVORW@cpan.org>') : ()),
);
