package perfSONAR_PS::Client::PSConfig::Translators::ApiConnect;

=head1 NAME

perfSONAR_PS::Client::PSConfig::Translators::ApiConnect - A class for building clients dedicated to translating

=head1 DESCRIPTION

A class for building clients dedicated to translating

=cut

use Mouse;
extends 'perfSONAR_PS::Client::PSConfig::ApiConnect';

our $VERSION = 4.1;

has 'translator_configs' => (is => 'rw', isa => 'ArrayRef[perfSONAR_PS::Client::PSConfig::Translators::BaseTranslator]', default => sub { [] });


=item translators()

Returns a list of possible translators

=cut

sub translators {   
    my $self = shift;
    
    return $self->translator_configs();
}

__PACKAGE__->meta->make_immutable;

1;