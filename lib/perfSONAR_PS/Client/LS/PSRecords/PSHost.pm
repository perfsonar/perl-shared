package perfSONAR_PS::Client::LS::PSRecords::PSHost;

=head1 NAME

perfSONAR_PS::Client::LS::PSRecords::PSHost - Defines perfSONAR network host record

=head1 DESCRIPTION

A base class for perfSONAR services. It inherits SimpleLookupService::Records::Network::Host. It defines few perfSONAR
specific keys

=cut

use strict;
use warnings;

our $VERSION = 3.3;

use base 'SimpleLookupService::Records::Network::Host';

use Params::Validate qw( :all );
use JSON qw( encode_json decode_json);
use perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames;
use perfSONAR_PS::Client::LS::PSKeywords::PSKeyValues;


sub init {
    my ( $self, @args ) = @_;
    
    $self->SUPER::init(@args); 
    
    return 0;
}

sub getRole {
    my $self = shift;
    return $self->{RECORD_HASH}->{(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_PSHOST_ROLE)};
}

sub setRole {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_PSHOST_ROLE), value=>$value  );
    
}

sub getAccessPolicy {
    my $self = shift;
    return $self->{RECORD_HASH}->{(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_PSHOST_ACCESSPOLICY)};
}

sub setAccessPolicy {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_PSHOST_ACCESSPOLICY), value=>$value  );
    
}

sub getAccessNotes {
    my $self = shift;
    return $self->{RECORD_HASH}->{(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_PSHOST_ACCESSNOTES)};
}

sub setAccessNotes {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_PSHOST_ACCESSNOTES), value=>$value  );
    
}

sub getBundle {
    my $self = shift;
    return $self->{RECORD_HASH}->{(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_PSHOST_BUNDLE)};
}

sub setBundle {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_PSHOST_BUNDLE), value=>$value  );
    
}

sub getBundleVersion {
    my $self = shift;
    return $self->{RECORD_HASH}->{(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_PSHOST_BUNDLEVERSION)};
}

sub setBundleVersion {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_PSHOST_BUNDLEVERSION), value=>$value  );
    
}

sub getToolkitVersion {
    #Deprecated in favor of getBundleVersion
    my $self = shift;
    return $self->{RECORD_HASH}->{(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_PSHOST_TOOLKITVERSION)};
}

sub setToolkitVersion {
    #Deprecated in favor of setBundleVersion
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
