package perfSONAR_PS::Client::LS::PSRecords::PSSignature;

=head1 NAME

perfSONAR_PS::Client::LS::PSRecords::PSSignature - Defines the details of perfSONAR signature

=head1 DESCRIPTION

perfSONAR specfic Signature record. it inherits SimpleLookupService::Records::Security::Signature;.

=cut

use strict;
use warnings;

our $VERSION = 3.3;

use base 'SimpleLookupService::Records::Security::Signature';

use Params::Validate qw( :all );
use JSON qw( encode_json decode_json);

sub init {
    my ( $self, @args ) = @_;
    my %parameters = validate( @args, {x509certificate => 1 } );
    
    $self->SUPER::init(%parameters); 
    
    return 0;
}
