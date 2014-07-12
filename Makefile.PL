use 5.010001;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'AnyEvent::Net::WOT',
    VERSION_FROM      => 'lib/AnyEvent/Net/WOT.pm', # finds $VERSION
	MAN3PODS          => {
		'lib/AnyEvent/Net/WOT.pm'           => 'blib/man3/AnyEvent::Net::WoT.3',
		'lib/AnyEvent/Net/WOT/Tarantool.pm' => 'blib/man3/AnyEvent::Net::WOT::Tarantool.3',
	},
    PREREQ_PM         => {
		AnyEvent::HTTP => 0,
		#AnyEvent::Tarantool => 0,
		AnyEvent => 0,
		Carp => 0,
		#Data::Dumper => 0,
		#Digest::SHA => 0,
		IO::Socket::SSL => 0,
		List::Util => 0,
		#MIME::Base64 => 0,
		Mouse => 0,
		URI => 0,
	},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/AnyEvent/Net/WOT.pm', # retrieve abstract from module
       AUTHOR         => 'Nikolay Shulyakovskiy <shulyakovskiy@mail.ru>') : ()),
);
