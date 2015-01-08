package Mail::MtPolicyd::Plugin::AddScoreHeader;

use Moose;
use namespace::autoclean;

our $VERSION = '1.14'; # VERSION
# ABSTRACT: mtpolicyd plugin for adding the score as header to the mail

extends 'Mail::MtPolicyd::Plugin';
with 'Mail::MtPolicyd::Plugin::Role::Scoring';
with 'Mail::MtPolicyd::Plugin::Role::UserConfig' => {
	'uc_attributes' => [ 'spam_score' ],
};

use Mail::MtPolicyd::Plugin::Result;


has 'header_name' => (
	is => 'ro', isa => 'Str',
	default => 'X-MtScore',
);

has 'spam_score' => ( is => 'ro', isa => 'Num', default => '5' );

sub run {
	my ( $self, $r ) = @_;
	my $score = $self->_get_score($r);
	my $spam_score = $self->get_uc($r->session, 'spam_score');
	my $value;
	if( ! defined $score ) {
		$self->log($r, 'score is undefined');
	}
	if( $score >= $spam_score ) {
		$value = 'YES ';
	} else {
		$value = 'NO ';
	}
	$value .= 'score='.$score;
	if( my $details = $self->_get_score_detail($r) ) {
		$value .= ' ['.$details.']';
	}

	return Mail::MtPolicyd::Plugin::Result->new_header_once(
		$r->is_already_done('score-'.$self->score_field.'-tag'),
		$self->header_name, $value );
}

__PACKAGE__->meta->make_immutable;

1;


__END__
=pod

=head1 NAME

Mail::MtPolicyd::Plugin::AddScoreHeader - mtpolicyd plugin for adding the score as header to the mail

=head1 VERSION

version 1.14

=head1 DESCRIPTION

Adds an header with the current score and score details to the mail.

=head1 PARAMETERS

=over

=item (uc_)spam_score (default: 5)

If the score is higher than this value it'll be tagged as 'YES'.
Otherwise 'NO'.

=item score_field (default: score)

Specifies the name of the field the score is stored in.
Could be set if you need multiple scores.

=item header_name (default: X-MtScore)

The name of the header to set.

=back

=head1 EXAMPLE

  <Plugin add-score-header>
    module = "AddScoreHeader"
    # score_field = "score"
    # header_name = "X-MtScore"
    spam_score = 5
  </Plugin>

Will return an action like:

  X-MtScore: YES score=7.5 [CTIPREP_TEMP=2.5, spamhaus-rbl=5]

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Markus Benning <ich@markusbenning.de>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

