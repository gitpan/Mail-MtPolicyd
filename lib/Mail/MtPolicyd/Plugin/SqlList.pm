package Mail::MtPolicyd::Plugin::SqlList;

use Moose;
use namespace::autoclean;

our $VERSION = '1.15'; # VERSION
# ABSTRACT: mtpolicyd plugin for accessing a SQL white/black/access list

extends 'Mail::MtPolicyd::Plugin';
with 'Mail::MtPolicyd::Plugin::Role::Scoring';
with 'Mail::MtPolicyd::Plugin::Role::UserConfig' => {
	'uc_attributes' => [ 'enabled' ],
};
with 'Mail::MtPolicyd::Plugin::Role::SqlUtils';

use Mail::MtPolicyd::Plugin::Result;


has 'enabled' => ( is => 'rw', isa => 'Str', default => 'on' );

has 'sql_query' => (
	is => 'rw', isa => 'Str',
	default => 'SELECT client_ip FROM whitelist WHERE client_ip=INET_ATON(?)',
);

has 'score' => ( is => 'rw', isa => 'Maybe[Num]' );
has 'match_action' => ( is => 'rw', isa => 'Maybe[Str]' );
has 'not_match_action' => ( is => 'rw', isa => 'Maybe[Str]' );

sub _query_db {
	my ( $self, $ip ) = @_;
	return $self->execute_sql($self->sql_query, $ip)->fetchrow_array;
}

sub run {
	my ( $self, $r ) = @_;
	my $ip = $r->attr('client_address');
	my $session = $r->session;
	my $config;

	if( $self->get_uc( $session, 'enabled') eq 'off' ) {
		return;
	}

	if( ! defined $ip) {
		$self->log($r, 'no attribute \'client_address\' in request');
		return;
	}

	my $value = $r->do_cached( $self->name.'-result',
		sub { $self->_query_db($ip) } );
	if( $value ) {
		$self->log($r, 'client_address '.$ip.' matched SqlList '.$self->name);
		if( defined $self->score
				&& ! $r->is_already_done($self->name.'-score') ) {
			$self->add_score($r, $self->name , $self->score);
		}
		if( defined $self->match_action ) {
			return Mail::MtPolicyd::Plugin::Result->new(
				action => $self->match_action,
				abort => 1,
			);
		}
	} else {
		$self->log($r, 'client_address '.$ip.' did not match SqlList '.$self->name);
		if( defined $self->not_match_action ) {
			return Mail::MtPolicyd::Plugin::Result->new(
				action => $self->not_match_action,
				abort => 1,
			);
		}
	}

	return;
}


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::MtPolicyd::Plugin::SqlList - mtpolicyd plugin for accessing a SQL white/black/access list

=head1 VERSION

version 1.15

=head1 SYNOPSIS

  <Plugin whitelist>
    module="SqlList"
    sql_query="SELECT client_ip FROM whitelist WHERE client_ip=?"
    match_action=dunno
  </Plugin>

  <Plugin blacklist>
    module="SqlList"
    sql_query="SELECT client_ip FROM blacklist WHERE client_ip=?"
    match_action="reject you are blacklisted!"
  </Plugin>

=head1 DESCRIPTION

Plugin checks the client_address against a SQL table.

Depending on wether a supplied SQL query matched actions can be taken.

=head2 PARAMETERS

The module takes the following parameters:

=over

=item (uc_)enabled (default: "on")

Could be set to 'off' to deactivate check. Could be used to activate/deactivate check per user.

=item sql_query (default: "SELECT client_ip FROM whitelist WHERE client_ip=INET_ATON(?)")

Prepared SQL statement to use for checking an IP address.

? will be replaced by the IP address.

The module will match if the statement returns one or more rows.

=back

By default the plugin will do nothing. One of the following actions should be specified:

=over

=item match_action (default: empty)

If given this action will be returned to the MTA if the SQL query matched.

=item not_match_action (default: empty)

If given this action will be returned to the MTA if the SQL query DID NOT matched.

=item score (default: empty)

If given this score will be applied to the session.

=back

=head1 EXAMPLE WITH A MYSQL TABLE

You may use the following table for storing ipv4 addresses in MySQL:

  CREATE TABLE `whitelist` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `client_ip` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `client_ip` (`client_ip`)
  ) ENGINE=MyISAM  DEFAULT CHARSET=latin1

  INSERT INTO whitelist VALUES(NULL, INET_ATON('127.0.0.1'));

And use it as a whitelist in mtpolicyd:

  <VirtualHost 12345>
    name="reputation"
    <Plugin whitelist>
      module="SqlList"
      sql_query="SELECT client_ip FROM whitelist WHERE client_ip=INET_ATON(?)"
      match_action="dunno"
    </Plugin>
    <Plugin trigger-greylisting>
    ...
  </VirtualHost>

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Markus Benning <ich@markusbenning.de>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
