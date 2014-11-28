package Mail::MtPolicyd::Client::App;

use Moose;

our $VERSION = '1.14'; # VERSION
# ABSTRACT: application interface class for Mail::MtPolicyd::Client


extends 'Mail::MtPolicyd::Client';
with 'MooseX::Getopt';

use Mail::MtPolicyd::Client::Request;
use IO::Handle;

has '+host' => (
        traits => ['Getopt'],
        cmd_aliases => "h",
        documentation => "host:port of a policyd",
);

has '+socket_path' => (
        traits => ['Getopt'],
        cmd_aliases => "s",
        documentation => "path to a socket of a policyd",
);


has '+keepalive' => (
        traits => ['Getopt'],
        cmd_aliases => "k",
        documentation => "use connection keepalive?",
);

has 'verbose' => (
	is => 'rw',
	isa => 'Bool',
	default => 0,
        traits => ['Getopt'],
        cmd_aliases => "v",
        documentation => "be verbose, print input/output to STDERR",
);

sub run {
	my $self = shift;
	my $stdin = IO::Handle->new;
	$stdin->fdopen(fileno(STDIN),"r");

	while( my $request = Mail::MtPolicyd::Client::Request->new_from_fh( $stdin ) ) {
		if( $self->verbose ) {
			$self->_dump('>> ', $request->as_string);
		}
		my $response = $self->request( $request );
		if( $self->verbose ) {
			$self->_dump('<< ', $response->as_string);
		}
		print $response->action."\n";
	}
	return;
}

sub _dump {
	my ( $self, $prefix, $message ) = @_;
	$message =~ s/^/$prefix/mg;
	print STDERR $message;
	return;
}


1;


__END__
=pod

=head1 NAME

Mail::MtPolicyd::Client::App - application interface class for Mail::MtPolicyd::Client

=head1 VERSION

version 1.14

=head1 SYNOPSIS

  use Mail::MtPolicyd::Client::App;

  my $app = Mail::MtPolicyd::Client::App->new_with_options();
  $app->run;

=head1 DESCRIPTION

This class provides a application interface for Mail::MtPolicyd::Client.

=head1 SEE ALSO

L<policyd-client>, L<Mail::MtPolicyd::Client>

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Markus Benning <ich@markusbenning.de>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

