use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'WWW::ICRT',
    VERSION_FROM      => 'lib/WWW/ICRT.pm',
    PREREQ_PM         => {
	'WWW::Mechanize' => '0.72',
	'Text::MicroMason' => '1.07',
	'File::Slurp' => '9999.03',
	'Mail::Mailer' => '1.60',
	'Regexp::Bind' => '0.02',
    },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/WWW/ICRT.pm',
       AUTHOR         => 'xern <xern@cpan.org>') : ()),
);
