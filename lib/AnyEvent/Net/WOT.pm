package AnyEvent::Net::WOT;

use strict;
use utf8;
use AnyEvent::HTTP;
use Mouse;
use AnyEvent::Net::WOT::Storage;
our $VERSION = '1.6';

=head1 NAME

AnyEvent::Net::WOT - AnyEvent Perl extension for the Web Of Trust API.

=head1 SYNOPSIS

  use AnyEvent;
  use AnyEvent::Net::WOT;
  use AnyEvent::Net::WOT::Tarantool;

  my $cv = AnyEvent->condvar;
  
  my $storage = AnyEvent::Net::WOT::Tarantool->new({
    host              => 'tarantool.host', 
	port              => '33013', 
	space             => 3, 
  });
  $storage->dbh->connect();

  my $wot = AnyEvent::Net::WOT->new({
	server => "http://api.mywot.com/0.4/public_link_json2",
	key => "key";
	storage => $storage,
  });
  my $url = 'example.COM';
  $wot->lookup( $url, sub {print $_->{url}->{target}; $cv->send()});
  $cv->recv;

=head1 DESCRIPTION

AnyEvent::Net::WOT implements the Web of Trust API.

=cut

has key              => ( is => 'rw', isa => 'Str',     required => 1 );
has server           => ( is => 'rw', isa => 'Str',     required => 1 );
has version          => ( is => 'rw', isa => 'Str',     default => '0.4' );
has api_method       => ( is => 'rw', isa => 'Str',     default => 'public_link_json2');
has user_agent       => ( is => 'rw', isa => 'Str',     default => 'AnyEvent::Net::WOT client '.$VERSION );
has http_timeout     => ( is => 'rw', isa => 'Num',     default => 1 );
has storage          => ( is => 'rw', isa => 'Object',  default => sub {AnyEvent::Net::WOT::Storage->new()});
has cache_bad_answer => ( is => 'rw', isa => 'Bool',    default => 0);
has default_answer   => ( is => 'rw', isa => 'HashRef', default => sub{ return {0 => [50, 50], 4 => [50, 50]}});

sub lookup {
	my ($self, $hosts, $cb_ret) = @_;
	$hosts = [$hosts] unless ref $hosts eq 'ARRAY';
	die "Required callback" unless $cb_ret;
	die "Must include at most 100 target names" if @$hosts > 100;
	my $map_host = {};
	foreach( @$hosts ){
		next unless m{/};
		my $uri = URI->new($_)->canonical;
		die "Bad url ".$_ if $uri->scheme !~ /^https?$/;
		$map_host->{$uri->host} = $_;
	}
	$self->storage->get_info_by_hosts(host => [ keys %$map_host ], cb => sub {
		my $ret = shift;
		my $url = join "/", $self->server, $self->version, $self->api_method;
		$url .= '?hosts=';
		my $need_wot_resp = 0;
		foreach ( keys %$map_host ){
			next if exists $ret->{$_} && !$ret->{$_}->{expired};
			$url .= $_.'/';
			$need_wot_resp = 1;
		}
		$url .= '&key='.$self->key;
		die "the full request path must also be less than 8 KiB or it will be rejected" if length($url) > 8192; #ToDo paralel request
		my $respons_processor = sub {
			my $resp = shift;
			foreach ( keys %$map_host ){
				$resp->{$map_host->{$_}} = delete $resp->{$_};
			}
			$cb_ret->($resp);
		};
		if($need_wot_resp){
			http_get $url, %{$self->param_for_http_req}, sub {
				my ($body, $header) = @_;
				my $result = {};
				eval{ $result = JSON::XS::decode_json($body) } if $header->{Status} == 200 && $body;
				foreach ( keys %$map_host ){
					$result->{$_} = {target => lc($_), %{$self->default_answer}, bad_answer => 1} if $self->cache_bad_answer && !exists $result->{$_};
					$ret->{$_} = {%{$result->{$_}}} if exists $result->{$_};
				}
				$respons_processor->($ret);
				$self->storage->set_info_by_hosts(host => $result, cb => sub {});
			};
		}
		else {
			$respons_processor->($ret);
		}
	});
	return;
}

=head2 param_for_http_req()

Generate params for http request

=cut

sub param_for_http_req {
	my $self = shift;
	return {timeout => $self->http_timeout, keepalive => 0, headers => { "user-agent" => $self->user_agent }}
}

1;

