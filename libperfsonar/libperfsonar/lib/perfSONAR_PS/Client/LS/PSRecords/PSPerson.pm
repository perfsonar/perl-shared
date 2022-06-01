package perfSONAR_PS::Client::LS::PSRecords::PSPerson;

=head1 NAME

perfSONAR_PS::Client::LS::PSRecords::PSPerson - Defines the perfsonar Person record

=head1 DESCRIPTION

perfSONAR specfic Person record. it inherits SimpleLookupService::Records::Directory::Person;.

=cut

use strict;
use warnings;

our $VERSION = 3.3;

use base 'SimpleLookupService::Records::Directory::Person';

use Params::Validate qw( :all );
use JSON qw( encode_json decode_json);

sub init {
    my ( $self, @args ) = @_;
    my %parameters = validate( @args, {personName => 1, emails => 1 } );
    
    $self->SUPER::init(%parameters); 
    
    return 0;
}
