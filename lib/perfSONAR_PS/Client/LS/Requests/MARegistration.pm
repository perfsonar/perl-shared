package perfSONAR_PS::Client::LS::Requests::MARegistration;

=head1 NAME

perfSONAR_PS::Client::LS::Requests::MARegistration - A registration record for measurement archives

=head1 DESCRIPTION

A sub class of perfSONAR_PS::Client::LS::Requests::Registration that defines additional fields
and utility functions useful for describing a measurement archive.

=cut

use strict;
use warnings;

use base 'perfSONAR_PS::Client::LS::Requests::Registration';

use Params::Validate qw( :all );
use perfSONAR_PS::Utils::ParameterValidation;

our $VERSION = 3.2;
use constant {
    SERVICE_TYPE_MA => "ma",
    LS_KEY_DATA_TYPES => "record-service-dataTypes"
};

sub init  {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { domain => 1, locator => 1} );
    
    return $self->SUPER::init({
           domain => $parameters->{"domain"},
           type => SERVICE_TYPE_MA,
           locator => $parameters->{"locator"},
    });
}

sub getStoredDataTypes {
    my $self = shift;
    return $self->{REG_HASH}->{(LS_KEY_DATA_TYPES)};
}

sub setStoredDataTypes {
    my ( $self, $value ) = @_;
    $self->addField(key => (LS_KEY_DATA_TYPES), value => $value);
}

sub getEndpoints {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { dataType => 1 } );
    return $self->{REG_HASH}->{"record-service-".$parameters->{dataType} . "-endpoints"};
}

sub setEndpoints {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { dataType => 1, endpoints => 1 } );
    $self->addField(key => "record-service-".$parameters->{dataType} . "-endpoints", 
        value => $parameters->{endpoints});
}