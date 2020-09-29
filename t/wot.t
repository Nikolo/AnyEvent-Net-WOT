
use strict;
use warnings;

use MR::Log;
use MR::OnlineConf;

use AnyEvent::Net::WOT;
use AnyEvent::Net::WOT::Tarantool;

use Test::More;

my $tarantool_wot = AnyEvent::Net::WOT::Tarantool->new(
    "master_server" => MR::OnlineConf->instance()->get("/clicker/tarantool/master"),
    "slave_server"  => MR::OnlineConf->instance()->get("/clicker/tarantool/slave"),
    "space"         => MR::OnlineConf->instance()->get("/clicker/tarantool/spaces/wot", 3),
);

$tarantool_wot->dbh->connect();

my $cvv = AE::cv;
my $timer = AE::timer 1, 0, sub { $cvv->send };
$cvv->recv();

my $wot = AnyEvent::Net::WOT->new(
    server           => MR::OnlineConf->instance()->get('/clicker/wot/server',           "https://scorecard.api.mywot.com"),
    key              => MR::OnlineConf->instance()->get('/clicker/wot/key',              ''),
    user_id          => 1,
    api_method       => MR::OnlineConf->instance()->get('/clicker/wot/api_method',       "targets"),
    storage          => $tarantool_wot,
    log_class        => 'MR::Log',
    cache_bad_answer => MR::OnlineConf->instance()->get('/clicker/wot/cache_bad_answer', 1),
);

my $cv = AE::cv;

$wot->lookup('https://google.com', sub { log_info( wot_resp => \@_ ); $cv->send(); });

$cv->recv();

ok(1);
done_testing();