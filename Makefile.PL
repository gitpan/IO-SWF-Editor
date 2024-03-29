use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'IO::SWF::Editor',
    VERSION_FROM      => 'lib/IO/SWF/Editor.pm', # finds $VERSION
    PREREQ_PM         => {
        'Image::Magick' => '6.6.3',
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/IO/SWF/Editor.pm', # retrieve abstract from module
       AUTHOR         => 'Seiji Harada <liptontea2k@gmail.com>') : ()),
);
