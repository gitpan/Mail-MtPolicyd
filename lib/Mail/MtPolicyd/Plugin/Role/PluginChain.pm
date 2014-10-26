package Mail::MtPolicyd::Plugin::Role::PluginChain;

use Moose::Role;

our $VERSION = '1.11'; # VERSION
# ABSTRACT: role for plugins to support a nested plugin chain

use Mail::MtPolicyd::PluginChain;

has 'chain' => (
	is => 'ro',
	isa => 'Maybe[Mail::MtPolicyd::PluginChain]',
	lazy => 1,
	default => sub {
		my $self = shift;
		if( defined $self->Plugin ) {
			return Mail::MtPolicyd::PluginChain->new_from_config(
				$self->vhost_name,
				$self->Plugin,
			);
		}
		return;
	},
);
has 'Plugin' => ( is => 'rw', isa => 'Maybe[HashRef]' );

1;


__END__
=pod

=head1 NAME

Mail::MtPolicyd::Plugin::Role::PluginChain - role for plugins to support a nested plugin chain

=head1 VERSION

version 1.11

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Markus Benning <ich@markusbenning.de>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

