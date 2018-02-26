package perfSONAR_PS::Client::PSConfig::ApiConnect;

=head1 NAME

perfSONAR_PS::Client::PSConfig::ApiConnect - A client for interacting with pSConfig

=head1 DESCRIPTION

A client for interacting with pSConfig

=cut

use Mouse;
use perfSONAR_PS::Client::PSConfig::BaseConnect;
use perfSONAR_PS::Client::PSConfig::Config;
use perfSONAR_PS::Client::PSConfig::Translators::MeshConfig::Config;
extends 'perfSONAR_PS::Client::PSConfig::BaseConnect';

our $VERSION = 4.1;

=item config_obj()

Return a perfSONAR_PS::Client::PSConfig::Config object

=cut

sub config_obj {
    return new perfSONAR_PS::Client::PSConfig::Config();
}

=item needs_translation()

Indicates needs translation unless there is an addresses field or includes.

=cut

sub needs_translation {
    my ($self, $json_obj) = @_;
    
    # optimization that looks for simple required field
    # proper way would be to validate, but expensive to do for just the MeshConfig
    unless($json_obj->{'addresses'} || $json_obj->{'includes'}){
        return 1;
    }
    
    return 0;
}

=item translators()

Returns a list of possible translators

=cut

sub translators {   
    my $self = shift;
    
    return [
        new perfSONAR_PS::Client::PSConfig::Translators::MeshConfig::Config('use_force_bidirectional' => 1),
    ];
}

__PACKAGE__->meta->make_immutable;

1;