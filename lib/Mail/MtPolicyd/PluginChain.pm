package Mail::MtPolicyd::PluginChain;

use Moose;
use namespace::autoclean;

our $VERSION = '1.12'; # VERSION
# ABSTRACT: class for a VirtualHost instance

use Mail::MtPolicyd::Result;

has 'plugins' => (
	is => 'ro',
	isa => 'ArrayRef[Mail::MtPolicyd::Plugin]',
	default => sub { [] },
	traits => [ 'Array' ],
	handles => {
		'add_plugin' => 'push',
	}
);

has 'plugin_prefix' => (
	is => 'ro', isa => 'Str', default => 'Mail::MtPolicyd::Plugin::',
);

has 'vhost_name' => ( is => 'rw', isa => 'Maybe[Str]' );

sub run {
	my ( $self, $r ) = @_;
	my $result = Mail::MtPolicyd::Result->new;

	foreach my $plugin ( @{$self->plugins} ) {
		my $abort = 0;
		my @plugin_results = $plugin->run($r);
		foreach my $plugin_result ( @plugin_results ) {
			$result->add_plugin_result($plugin_result);
			if( $plugin_result->abort ) {
				$abort = 1;
			}
		}
		if( $abort ) { last; }
	}

	return $result;
}

sub load_plugin {
	my ( $self, $plugin_name, $params ) = @_;
	if( ! defined $params->{'module'} ) {
		die('no module defined for plugin '.$plugin_name.'!');
	}
	my $module = $params->{'module'};
	my $plugin_class = $self->plugin_prefix.$module;
	my $plugin;

	my $code = "require ".$plugin_class.";";
	eval $code; ## no critic (ProhibitStringyEval)
	if($@) {
		die('could not load module '.$module.' for plugin '.$plugin_name.': '.$@);
        }

	eval {
                $plugin = $plugin_class->new(
			name => $plugin_name,
			vhost_name => $self->vhost_name,
			%$params,
		);
        };
        if($@) {
		die('could not initialize plugin '.$plugin_name.': '.$@);
        }
	$self->add_plugin($plugin);
	return;
}

sub new_from_config {
	my ( $class, $vhost_name, $config ) = @_;

	my $self = $class->new( vhost_name => $vhost_name );

	if( ! defined $config ) {
		return( $self );
	}

	if( ref($config) ne 'HASH' ) {
		die('config must be an hashref!');
	}

	foreach my $plugin_name ( keys %{$config} ) {
		$self->load_plugin($plugin_name,
			$config->{$plugin_name} );
	}

	return $self;
}

__PACKAGE__->meta->make_immutable;

1;


__END__
=pod

=head1 NAME

Mail::MtPolicyd::PluginChain - class for a VirtualHost instance

=head1 VERSION

version 1.12

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Markus Benning <ich@markusbenning.de>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
