package Mail::MtPolicyd::Plugin::SqlUserConfig;

use Moose;
use namespace::autoclean;

our $VERSION = '1.13'; # VERSION
# ABSTRACT: mtpolicyd plugin for retrieving the user config of a user

extends 'Mail::MtPolicyd::Plugin';


use Mail::MtPolicyd::Plugin::Result;
use JSON;

has 'sql_query' => (
	is => 'rw', isa => 'Str',
	default => 'SELECT config FROM user_config WHERE address=?',
);

has '_json' => (
	is => 'ro', isa => 'JSON', lazy => 1,
	default => sub {
		return JSON->new;
	}
);

sub _get_config {
	my ( $self, $r ) = @_;
	my $rcpt = $r->attr('recipient');

	my $dbh = $r->server->get_dbh;
	my $sth = $dbh->prepare( $self->sql_query );
	$sth->execute( $rcpt );
	my ( $json ) = $sth->fetchrow_array;
	if( ! defined $json ) {
		die( 'no user-config found for '.$rcpt );
	}
	return $self->_json->decode( $json );
}

sub run {
	my ( $self, $r ) = @_;
	my $config;

	if( ! defined $r->attr('recipient') ) {
		$self->log($r, 'no attribute \'recipient\' in request');
		return;
	}

	eval { $config = $self->_get_config($r) };
	if( $@ ) {
		$self->log($r, 'unable to retrieve user-config: '.$@);
		return;
	}

	foreach my $key ( keys %$config ) {
		$r->session->{$key} = $config->{$key};
	}

	return;
}


__PACKAGE__->meta->make_immutable;

1;


__END__
=pod

=head1 NAME

Mail::MtPolicyd::Plugin::SqlUserConfig - mtpolicyd plugin for retrieving the user config of a user

=head1 VERSION

version 1.13

=head1 DESCRIPTION

This plugin will retrieve a JSON string from an SQL database and will merge the data structure
into the current session.

This could be used to retrieve configuration values for users from a database.

=head1 PARAMETERS

=over

=item sql_query (default: SELECT config FROM user_config WHERE address=?)

The SQL query to retrieve the JSON configuration string.

The content of the first row/column is used.

=back

=head1 EXAMPLE USER SPECIFIC GREYLISTING

Create the following table in the SQL database:

 CREATE TABLE `user_config` (
   `id` int(11) NOT NULL AUTO_INCREMENT,
   `address` varchar(255) DEFAULT NULL,
   `config` TEXT NOT NULL,
   PRIMARY KEY (`id`),
   UNIQUE KEY `address` (`address`)
 ) ENGINE=MyISAM  DEFAULT CHARSET=latin1

 INSERT INTO TABLE `user_config` VALUES( NULL, 'karlson@vomdach.de', '{"greylisting":"on"}' );

In mtpolicyd.conf:

  db_dsn="dbi:mysql:mail"
  db_user=mail
  db_password=password

  <Plugin user-config>
    module = "SqlUserConfig"
    sql_query = "SELECT config FROM user_config WHERE address=?"
  </Plugin>
  <Plugin greylist>
    enabled = "off" # off by default
    uc_enabled = "greylisting" # override with value of key 'greylisting' is set in session
    module = "Greylist"
    score = -5
    mode = "passive"
  </Plugin>

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Markus Benning <ich@markusbenning.de>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

