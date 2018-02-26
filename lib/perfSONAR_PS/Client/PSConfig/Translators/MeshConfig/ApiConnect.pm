package perfSONAR_PS::Client::PSConfig::Translators::MeshConfig::ApiConnect;

=head1 NAME

perfSONAR_PS::Client::PSConfig::Translators::MeshConfig::ApiConnect - A client for interacting with MeshConfig

=head1 DESCRIPTION

A client for interacting with MeshConfig

=cut

use Mouse;
use perfSONAR_PS::Client::PSConfig::BaseConnect;
use perfSONAR_PS::Client::PSConfig::Translators::MeshConfig::Config;

extends 'perfSONAR_PS::Client::PSConfig::BaseConnect';

our $VERSION = 4.1;

=item config_obj()

Return a perfSONAR_PS::Client::PSConfig::Translators::MeshConfig::Config object

=cut

sub config_obj {
    return new perfSONAR_PS::Client::PSConfig::Translators::MeshConfig::Config();
}

__PACKAGE__->meta->make_immutable;

1;