package perfSONAR_PS::Client::LS::Requests::Registration;

=head1 NAME

perfSONAR_PS::Client::LS::Requests::Registration - The base class for Lookup Service Registrations

=head1 DESCRIPTION

A base class for Lookup Service registrations. It defines the fields used by all 
registrations. Specific types of service records may become subclasses of this class. It 
allows for any key to be added with the addField function.

=cut

use strict;
use warnings;

our $VERSION = 3.2;

use Params::Validate qw( :all );
use perfSONAR_PS::Utils::ParameterValidation;

use fields 'REG_HASH';

use constant {
    LS_KEY_RECORD_TYPE => "record-type",
    LS_KEY_DOMAIN => "record-service-domain",
    LS_KEY_LOCATOR => "record-service-locator",
    LS_KEY_TYPE => "record-service-type",
    LS_KEY_NAME => "record-service-name",
    LS_KEY_DESCRIPTION => "record-service-description",
    LS_KEY_PRIVATEKEY => "record-service-privatekey",
    LS_KEY_TTL => "record-service-ttl",
    LS_KEY_SITE_LOCATION => "record-service-site_location",
    RECORD_TYPE_SERVICE => "service",
};

sub new {
    my $package = shift;

    my $self = fields::new( $package );
   
    return $self;
}

sub init {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { domain => 1, locator => 1, type => 1 } );
    
    unless(ref($parameters->{domain}) eq 'ARRAY'){
        $parameters->{domain} = [ $parameters->{domain} ];
    }
    
    unless(ref($parameters->{locator}) eq 'ARRAY'){
        $parameters->{locator} = [ $parameters->{locator} ];
    }
    
    unless(ref($parameters->{type}) eq 'ARRAY'){
        $parameters->{type} = [ $parameters->{type} ];
    }
    
    $self->{REG_HASH} = {
            (LS_KEY_RECORD_TYPE) => [ (RECORD_TYPE_SERVICE) ],
            (LS_KEY_DOMAIN) => $parameters->{domain},
            (LS_KEY_LOCATOR) => $parameters->{locator},
            (LS_KEY_TYPE) => $parameters->{type},
        };
   
    return 0;
}

sub _makeArray {
    my ($self, $var) = @_;
  
    unless(ref($var) eq 'ARRAY'){
        $self->{INSTANCE} = [ $self->{INSTANCE} ];
    }
}



sub addField {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { key => 1, value => 1 } );
    
    $self->{REG_HASH}->{$parameters->{key}} = $parameters->{value}; 
}

sub getRegHash {
    my $self = shift;
    return $self->{REG_HASH};
}

sub getServiceDomain {
    my $self = shift;
    return $self->{REG_HASH}->{(LS_KEY_DOMAIN)};
}

sub setServiceDomain {
    my ( $self, $value ) = @_;
    $self->addField(key => (LS_KEY_DOMAIN), value => $value);
}

sub getServiceLocator {
    my $self = shift;
    return $self->{REG_HASH}->{(LS_KEY_LOCATOR)};
}

sub setServiceLocator {
    my ( $self, $value ) = @_;
    $self->addField(key => (LS_KEY_LOCATOR), value => $value);
}

sub getServiceType {
    my $self = shift;
    return $self->{REG_HASH}->{(LS_KEY_TYPE)};
}

sub setServiceType {
    my ( $self, $value ) = @_;
    $self->addField(key => (LS_KEY_TYPE), value => $value);
}

sub getServiceName {
    my $self = shift;
    return $self->{REG_HASH}->{(LS_KEY_NAME)};
}

sub setServiceName {
    my ( $self, $value ) = @_;
    $self->addField(key => (LS_KEY_NAME), value => $value);
}

sub getServiceDescription {
    my $self = shift;
    return $self->{REG_HASH}->{(LS_KEY_DESCRIPTION)};
}

sub setServiceDescription {
    my ( $self, $value ) = @_;
    $self->addField(key => (LS_KEY_DESCRIPTION), value => $value);
}

sub getServicePrivateKey {
    my $self = shift;
    return $self->{REG_HASH}->{(LS_KEY_PRIVATEKEY)};
}

sub setServicePrivateKey {
    my ( $self, $value ) = @_;
    $self->addField(key => (LS_KEY_PRIVATEKEY), value => $value);
}

sub getServiceTTL {
    my $self = shift;
    return $self->{REG_HASH}->{(LS_KEY_TTL)};
}

sub setServiceTTL {
    my ( $self, $value ) = @_;
    $self->addField(key => (LS_KEY_TTL), value => $value);
}

sub getServiceSiteLocation {
    my $self = shift;
    return $self->{REG_HASH}->{(LS_KEY_SITE_LOCATION)};
}

sub setServiceSiteLocation {
    my ( $self, $value ) = @_;
    $self->addField(key => (LS_KEY_SITE_LOCATION), value => $value);
}