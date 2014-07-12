# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl AnyEvent-Net-SafeBrowsing2.t'

#########################


use List::Util qw(first);
use Test::More qw(no_plan);
BEGIN { use_ok('AnyEvent::Net::WOT') };

require_ok( 'AnyEvent::Net::WOT' );


#########################

my $wot = AnyEvent::Net::WOT->new( server => 'test', key => 'test', );

