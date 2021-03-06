package Mail::MtPolicyd::Plugin::Proxy;

use Moose;
use namespace::autoclean;

our $VERSION = '1.15'; # VERSION
# ABSTRACT: mtpolicyd plugin to forward request to another policy daemon


extends 'Mail::MtPolicyd::Plugin';

use Mail::MtPolicyd::Plugin::Result;

use Mail::MtPolicyd::Client;
use Mail::MtPolicyd::Client::Request;

has 'socket_path' => ( is => 'rw', isa => 'Maybe[Str]' );
has 'host' => ( is => 'rw', isa => 'Maybe[Str]' );
has 'keepalive' => ( is => 'rw', isa => 'Bool', default => 0 );

has _client => (
	is => 'ro', isa => 'Mail::MtPolicyd::Client', lazy => 1,
	default => sub {
		my $self = shift;
		my %opts = (
			keepalive => $self->keepalive,
		);
		if( defined $self->socket_path ) {
			$opts{'socket_path'} = $self->socket_path;
		} elsif( defined $self->host ) {
			$opts{'host'} = $self->host;
		} else {
			$self->logdie('no host and no socket_path configured!');
		}
		return Mail::MtPolicyd::Client->new( %opts );
	},
);

sub run {
	my ( $self, $r ) = @_;

	my $proxy_request = Mail::MtPolicyd::Client::Request->new_proxy_request( $r );
	my $response = $self->_client->request( $proxy_request );

	return Mail::MtPolicyd::Plugin::Result->new(
		action => $response->action,
		abort => 1,
	);
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::MtPolicyd::Plugin::Proxy - mtpolicyd plugin to forward request to another policy daemon

=head1 VERSION

version 1.15

=head1 DESCRIPTION

This module forwards the request to another policy daemon.

=head1 PARAMETERS

=over

=item host (default: empty)

The <host>:<port> of the target policy daemon.

=item socket_path (default: empty)

The path to the socket of the target policy daemon.

=item keepalive (default: 0)

Keep connection open across requests.

=back

=head1 EXAMPLE

  <Plugin ask-postgrey>
    module = "Proxy"
    host="localhost:10023"
  </Plugin>

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Markus Benning <ich@markusbenning.de>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
