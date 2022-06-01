package SimpleLookupService::QueryObjects::Security::SignatureQueryObject;

use strict;
use warnings FATAL => 'all';

=head1 NAME

SimpleLookupService::QueryObjects::Security::SignatureQueryObject - Query Object for signature

=head1 DESCRIPTION

Query Object for signature records.

=cut

use strict;
use warnings;

our $VERSION = 3.3;

use base 'SimpleLookupService::QueryObjects::QueryObject';

use Params::Validate qw( :all );
use JSON qw( encode_json decode_json);
use SimpleLookupService::Keywords::KeyNames;
use SimpleLookupService::Keywords::Values;


sub init {
    my ( $self, @args ) = @_;

    $self->SUPER::init(type=>(SimpleLookupService::Keywords::Values::LS_VALUE_TYPE_SIGNATURE));

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