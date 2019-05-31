package SimpleLookupService::BulkRenewResponse;
use strict;
use warnings;


use base 'SimpleLookupService::Message';
use Carp qw(cluck);

sub init {
    my ( $self ) = @_;

    $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_RESPONSE_BULKRENEW_TOTAL)}=0;
    $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_RESPONSE_BULKRENEW_FAILURE)}=0;
    $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_RESPONSE_BULKRENEW_RENEWED)}=0;

    $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_RESPONSE_BULKRENEW_FAILED_URIS)}=[];
    $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_RESPONSE_BULKRENEW_ERROR_CODE)} =[];
    $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_RESPONSE_BULKRENEW_ERROR_MESSAGE)}=[];


    return 0;
}

sub getTotal {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_RESPONSE_BULKRENEW_TOTAL)};
}

sub getFailed {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_RESPONSE_BULKRENEW_FAILURE)};
}

sub getRenewed {
    my $self = shift;

    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_RESPONSE_BULKRENEW_RENEWED)};
}

sub getFailedUris {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_RESPONSE_BULKRENEW_FAILED_URIS)};
}

sub getErrorCodes {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_RESPONSE_BULKRENEW_ERROR_CODE)};
}

sub getErrorMessages {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_RESPONSE_BULKRENEW_ERROR_MESSAGE)};
}

sub validate {
    my $self = shift;
    unless (defined $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_RESPONSE_BULKRENEW_TOTAL)}){
        $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_RESPONSE_BULKRENEW_TOTAL)}=0;
    }

    unless (defined $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_RESPONSE_BULKRENEW_RENEWED)}){
        $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_RESPONSE_BULKRENEW_RENEWED)}=0;
    }

    unless (defined $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_RESPONSE_BULKRENEW_FAILURE)}){
        $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_RESPONSE_BULKRENEW_FAILURE)}=0;
    }

    unless (defined $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_RESPONSE_BULKRENEW_FAILED_URIS)}){
        $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_RESPONSE_BULKRENEW_FAILED_URIS)}=[];
    }

    unless (defined $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_RESPONSE_BULKRENEW_ERROR_MESSAGE)}){
        $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_RESPONSE_BULKRENEW_ERROR_MESSAGE)}=[];
    }
    unless (defined $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_RESPONSE_BULKRENEW_ERROR_CODE)}){
        $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_RESPONSE_BULKRENEW_ERROR_CODE)}=[];
    }

}


1;