package AnyEvent::Net::WOT::Storage;

use strict;
use warnings;
use Mouse;

=head1 NAME

AnyEvent::Net::WOT::Storage - Base class for caching the WOT response

=head1 SYNOPSIS

  package AnyEvent::Net::WOT::Tarantool;

  use base 'AnyEvent::Net::WOT::Storage';

=head1 DESCRIPTION

This is the base class for implementing a storage mechanism for the WOT cache. See L<AnyEvent::Net::WOT::Tarantool> for an example of implementation.

This module cannot be used on its own as it does not actually store anything. All methods should redefined. Check the code to see which arguments are used, and what should be returned.

=cut

=head1 CONSTRUCTOR

=over 4

=back

=head2 new()

  Create a AnyEvent::Net::WOT::Storage object

  my $storage	=> AnyEvent::Net::WOT::Storage->new();

Arguments

=over 4

=item master_server

Optional. Master address database server host:port

=back

=item slave_server

Optional. Slave address database server host:port

=back

=item log

Required. Class for log writing. Default AnyEvent::Net::WOT::Log

=cut

has master_server => ( is => 'rw', isa => 'Str' );
has slave_server  => ( is => 'rw', isa => 'Str' );
has dbh           => ( is => 'rw', isa => 'Object' );
has log_class     => ( is => 'rw', isa => 'Str', default => 'AnyEvent::Net::WOT::Log' );

=head1 PUBLIC FUNCTIONS

=over 4

=back

=head2 get_info_by_hosts()

Getting info by hosts from local cache

	$storage->get_info_by_hosts(host => ['example.net'], cb => sub {});

Arguments

=over 4

=item host

Required. Array of host

=item cb

CodeRef what be called after request to db

=back

=cut

sub get_info_by_hosts { die "unimplemented method called!" }

=head2 set_info_by_host()

Set info by hosts to local cache

	$storage->set_info_by_hosts(host => {'example.net' => {0 => [1,2], 1 => [3,4], blacklist => []}}, cb => sub {});

Arguments

=over 4

=item host

Required. Hash of answer from wot 

=item cb

CodeRef what be called after request to db

=back

=cut

sub set_info_by_host { die "unimplemented method called!" }

no Mouse;
__PACKAGE__->meta->make_immutable();

=head1 SEE ALSO

See L<AnyEvent::Net::WOT> for handling WOT.

See L<AnyEvent::Net::WOT::Tarantool> or L<AnyEvent::Net::WOT::Empty> for an example of storing and managing the Safe Browsing database.

WOT API: L<https://www.mywot.com/wiki/API>

=head1 AUTHOR

Nikolay Shulyakovskiy, or E<lt>shulyakovskiy@mail.ruE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Nikolay Shulyakovsky

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
