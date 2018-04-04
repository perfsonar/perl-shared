package perfSONAR_PS::Client::PSConfig::Translators::BaseTranslator;

=head1 NAME

perfSONAR_PS::Client::PSConfig::Translators::BaseTranslator - Abstract class for config object that reads input and translates to another format

=head1 DESCRIPTION

Abstract class for client that reads input and translates to another format

=cut

use Mouse;

extends 'perfSONAR_PS::Client::PSConfig::BaseNode';

our $VERSION = 4.1;

has 'error' => (is => 'ro', isa => 'Str', writer => '_set_error');

sub name {
    my ($self);
    ##
    # Override this with method with name of translator
    die 'Override name';
}

sub can_translate {
    my ($self, $raw_config, $json_obj);
    ##
    # Override this with method to look at given raw config and/or json object and 
    # determines if this class is able to translate
    die 'Override can_translate';
}

sub translate {
    my ($self, $raw_config, $json_obj);
    ##
    # Override this with method to translate given raw config or object to target format
    die 'Override translate';
}

__PACKAGE__->meta->make_immutable;

1;