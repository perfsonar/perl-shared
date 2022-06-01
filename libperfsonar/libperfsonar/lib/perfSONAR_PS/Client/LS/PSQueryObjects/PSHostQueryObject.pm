package perfSONAR_PS::Client::LS::PSQueryObjects::PSHostQueryObject;

=head1 NAME

perfSONAR_PS::Client::LS::PSQueryObjects::PSHostQueryObject - Defines query object for perfSONAR host

=head1 DESCRIPTION

A base query class for perfSONAR services. It inherits SimpleLookupService::QueryObjects::Network::HostQueryObject. It defines few perfSONAR
specific keys

=cut

use strict;
use warnings;

our $VERSION = 3.3;

use base 'SimpleLookupService::QueryObjects::Network::HostQueryObject';

use Params::Validate qw( :all );
use JSON qw( encode_json decode_json);
use perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames;
use perfSONAR_PS::Client::LS::PSKeywords::PSKeyValues;


sub init {
 my ( $self, @args ) = @_;
    
    $self->SUPER::init(); 
    
    return $self;
}

sub getToolkitVersion {
    my $self = shift;
    return $self->{RECORD_HASH}->{(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_PSHOST_TOOLKITVERSION)};
}

sub setToolkitVersion {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_PSHOST_TOOLKITVERSION), value=>$value  );
    
}

sub getCommunities {
    my $self = shift;
    return $self->{RECORD_HASH}->{(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_GROUP_COMMUNITIES)};
}

sub setCommunities {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_GROUP_COMMUNITIES), value=>$value  );
    
}
