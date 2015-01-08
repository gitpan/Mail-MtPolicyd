package Mail::MtPolicyd::Plugin::Eval;

use Moose;
use namespace::autoclean;

our $VERSION = '1.15'; # VERSION
# ABSTRACT: mtpolicyd plugin to capture the output of plugins


extends 'Mail::MtPolicyd::Plugin';
with 'Mail::MtPolicyd::Plugin::Role::PluginChain';

has 'store_in' => ( is => 'ro', isa => 'Str', required => 1 );

sub run {
	my ( $self, $r ) = @_;
	my $field = $self->store_in;

	if( ! defined $self->chain ) {
		return;
	}

	my $chain_result = $self->chain->run( $r );
	my @actions = $chain_result->actions;

	if( scalar @actions ) {
		$r->session->{$field} = join("\n", @actions)
	}

	return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::MtPolicyd::Plugin::Eval - mtpolicyd plugin to capture the output of plugins

=head1 VERSION

version 1.15

=head1 DESCRIPTION

This plugin executes a list of configured plugins but will not return the
action back to mtpolicyd. Instead it writes the output of the plugins to a
variable within the session.

=head1 PARAMETERS

=over

=item store_in (required)

The name of the key in the session to store the result of the eval'ed checks.

=item Plugin (required)

A list of checks to execute.

=back

=head1 EXAMPLE

  <Plugin eval-spf>
    module = "Eval"
    # store result in spf_action
    store_in="spf_action"
    <Plugin proxy-spf>
      module = "Proxy"
      host = "localhost:10023"
    </Plugin>
  </Plugin>

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Markus Benning <ich@markusbenning.de>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
