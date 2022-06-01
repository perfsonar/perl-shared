package perfSONAR_PS::Client::LS::PSQueryObjects::PSPersonQueryObject;

=head1 NAME

perfSONAR_PS::Client::LS::PSQueryObjects::PSPersonQueryObject - Defines query object for perfSONAR Person

=head1 DESCRIPTION

A base query class for perfSONAR services. It inherits SimpleLookupService::QueryObjects::Network::InterfaceQueryObject. It defines few perfSONAR
specific keys

=cut

use strict;
use warnings;

our $VERSION = 3.3;

use base 'SimpleLookupService::QueryObjects::Directory::PersonQueryObject';

use Params::Validate qw( :all );
use JSON qw( encode_json decode_json);
use perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames;
use perfSONAR_PS::Client::LS::PSKeywords::PSKeyValues;


sub init {
 my ( $self, @args ) = @_;
    
    $self->SUPER::init(); 
    
    return $self;
}
