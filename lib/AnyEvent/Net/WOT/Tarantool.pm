package AnyEvent::Net::WOT::Tarantool;

use strict;
use utf8;
use Mouse;
use AnyEvent::Tarantool;
use AnyEvent::Tarantool::Cluster;

extends 'AnyEvent::Net::WOT::Storage';

has space             => (is => 'rw', isa => 'Int', required => 1);
has all_connected     => (is => 'ro', isa => 'CodeRef', default => sub {return sub{}});
has caching_time      => ( is => 'rw', isa => 'Num', default => 60*60*24 );
has bad_caching_time  => ( is => 'rw', isa => 'Num', default => 60*30);


sub BUILD {
	my $self = shift;
	eval "use ".$self->log_class.";";
	die $@ if $@;
	my $servers = [];
	die "master_server is required" unless $self->master_server;
	foreach( split ',', $self->master_server ){
		my $srv = {master => 1};
		($srv->{host}, $srv->{port}) = split ":", $_;
		push @$servers, $srv;
	}
	foreach( split ',', $self->slave_server ){
		my $srv = {};
		($srv->{host}, $srv->{port}) = split ":", $_;
		push @$servers, $srv;
	}
	$self->dbh(AnyEvent::Tarantool::Cluster->new(
		servers => $servers,
		spaces => {
			$self->space() => {
				name         => 'wot_cache',
				fields       => [qw/host resp update_date bad_answer/],
				types        => [qw/STR  STR NUM     NUM/],
				indexes      => {
					0 => {
						name => 'idx_a_uniq',
						fields => ['host'],
					},
				},
			},
		},
		all_connected => $self->all_connected,
	));
	return $self;
}

sub get_info_by_hosts {
	my ($self, %args) = @_;
	my $host       = $args{host}; ref $args{host} eq 'ARRAY'|| die "host arg is required and must be ARRAYREF";
	my $cb         = $args{'cb'}; ref $args{'cb'} eq 'CODE' || die "cb arg is required and must be CODEREF";
	if ($self->dbh && $self->dbh->slave) {
		$self->dbh->slave->select('wot_cache', [map {lc($_)} @$host] , {index => 0}, sub{
			my ($result, $error) = @_;
			if( $error || !$result->{count} ){
				log_error( "Tarantool error: ".$error ) if $error;
				$cb->({});
			}
			else {
				if ($self->dbh->master) {
					my $ret = {};
					my $space = $self->dbh->master->{spaces}->{wot_cache};
					foreach my $tup ( @{$result->{tuples}} ){
						my $tmp_ret = {map {$_->{name} => $tup->[$_->{no}]||''} @{$space->{fields}}};
						if( ($tmp_ret->{bad_answer} && AnyEvent->now() - $tmp_ret->{update_date} > $self->bad_caching_time ) || (AnyEvent->now() - $tmp_ret->{update_date} > $self->caching_time)){
							$tmp_ret->{expired} = 1;
						}
						my ($tmp_host) = grep {lc($_) eq $tmp_ret->{host}} @$host;
						$ret->{$tmp_host} = {target => $tmp_ret->{host}, %{JSON::XS::decode_json($tmp_ret->{resp})}, expired => ($tmp_ret->{expired}||0)};
					}
					$cb->($ret); 
				}
				else {
					log_error( 'WOT tarantool master-server is unavailable' );
					$cb->({});
				}
			}
		});
	}
	else {
		log_error( 'WOT tarantool slave-server is unavailable' );
		$cb->({});
	}

	return;
}

sub set_info_by_hosts {
	my ($self, %args) = @_;
	my $host       = $args{host}; ref $args{host} eq 'HASH' || die "host arg is required and must be HASHREF";
	my $cb         = $args{'cb'}; ref $args{'cb'} eq 'CODE' || die "cb arg is required and must be CODEREF";
	if ($self->dbh && $self->dbh->master) {
		$self->dbh->master->lua( 'wot_cache.add_to_wot_cache', [$self->space(), JSON::XS::encode_json($host)], {in => 'pp', out => 'p'}, sub {
			my ($result, $error) = @_;
			log_error( "Tarantool error: ",$error ) if $error;
			$cb->($error ? 1 : 0);
		});
	}
	else {
		log_error( 'WOT tarantool master-server is unavailable' );
		$cb->(1);
	}
	return;
}

1;
