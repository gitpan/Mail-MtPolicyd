package Mail::MtPolicyd::SqlConnection;

use strict;
use MooseX::Singleton;

# ABSTRACT: singleton class to hold the sql database connection
our $VERSION = '1.15'; # VERSION

use DBI;

has 'dsn' => ( is => 'ro', isa => 'Str', required => 1 );
has 'user' => ( is => 'ro', isa => 'Str', required => 1 );
has 'password' => ( is => 'ro', isa => 'Str', required => 1 );

has 'dbh' => ( is => 'ro', isa => 'DBI::db', lazy => 1,
    default => sub {
        my $self = shift;
        my $dbh = DBI->connect(
            $self->dsn,
			$self->user,
            $self->password,
            {
				RaiseError => 1,
                PrintError => 0,
				AutoCommit => 1,
				mysql_auto_reconnect => 1,
			},
		);
        return $dbh;
    },
    handles => [ 'disconnect' ],
);

sub is_initialized {
    my ( $class, @args ) = @_;

    if( $class->meta->existing_singleton ) {
        return( 1 );
    }
    return( 0 );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::MtPolicyd::SqlConnection - singleton class to hold the sql database connection

=head1 VERSION

version 1.15

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Markus Benning <ich@markusbenning.de>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
