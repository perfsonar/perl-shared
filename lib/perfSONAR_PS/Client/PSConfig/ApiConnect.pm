package perfSONAR_PS::Client::PSConfig::ApiConnect;

=head1 NAME

perfSONAR_PS::Client::PSConfig::ApiConnect - A client for interacting with pSConfig

=head1 DESCRIPTION

A client for interacting with pSConfig

=cut

use Mouse;
use perfSONAR_PS::Client::PSConfig::BaseConnect;
use perfSONAR_PS::Client::PSConfig::Config;

extends 'perfSONAR_PS::Client::PSConfig::BaseConnect';

our $VERSION = 4.1;

sub config_obj {
    #return a perfSONAR_PS::Client::PSConfig::Config object
    return new perfSONAR_PS::Client::PSConfig::Config();
}


__PACKAGE__->meta->make_immutable;

1;