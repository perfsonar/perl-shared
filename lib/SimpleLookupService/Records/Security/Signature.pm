package SimpleLookupService::Records::Security::Signature;
=head1 NAME

SimpleLookupService::Records::Security::Signature - Class that deals with signature details

=head1 DESCRIPTION

A base class for registering signature information. Defines fields to register x509 certificate location, signature encoding, digest, etc
another record

=cut

use strict;
use warnings;

our $VERSION = 3.3;

use Carp qw(cluck);
use SimpleLookupService::Keywords::Values;
use Params::Validate qw( :all );

use base 'SimpleLookupService::Records::Record';

my $DIGEST = "sha256";
my $SIGNATURE_ENCODING = "base64";

sub init {
    my ( $self, @args ) = @_;
    my %parameters = validate( @args, {x509certificate => 0 } );

    $self->SUPER::init(type=>(SimpleLookupService::Keywords::Values::LS_VALUE_TYPE_SIGNATURE));
    $self->setDigest($DIGEST);
    $self->setSignatureEncoding($SIGNATURE_ENCODING);

    if(defined $parameters{x509certificate}){
        my $ret = $self->setCertificate($parameters{x509certificate});
        if($ret <0){
            cluck "Error initializing certificate";
            return $ret;
        }
    }

    return 0;
}

sub getDigest {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_SIGNATURE_DIGEST)};
}

sub setDigest {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_SIGNATURE_DIGEST), value=>$value  );

}

sub getCertificate {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_SIGNATURE_CERTIFICATE)};
}

sub setCertificate {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_SIGNATURE_CERTIFICATE), value=>$value  );

}

sub getSignatureEncoding {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_SIGNATURE_ENCODING)};
}

sub setSignatureEncoding {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_SIGNATURE_ENCODING), value=>$value  );

}

1;