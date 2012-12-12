package perfSONAR_PS::Client::LS::PSRecords::PSHost;

=head1 NAME

perfSONAR_PS::Client::LS::PSRecords::PSHost - Defines perfSONAR network host record

=head1 DESCRIPTION

A base class for perfSONAR services. It inherits SimpleLookupService::Records::Network::Host. It defines few perfSONAR
specific keys

=cut

use strict;
use warnings;

our $VERSION = 3.2;

use base 'SimpleLookupService::Records::Network::Host';

use Params::Validate qw( :all );
use JSON qw( encode_json decode_json);
use perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames;
use perfSONAR_PS::Client::LS::PSKeywords::PSKeyValues;


sub init {
    my ( $self, @args ) = @_;
    my %parameters = validate( @args, { hostName => 1} );
    
    $self->SUPER::init(%parameters); 
    
    return 0;
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