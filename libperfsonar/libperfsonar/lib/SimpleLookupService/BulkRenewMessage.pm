package SimpleLookupService::BulkRenewMessage;

=head1 NAME

SimpleLookupService::BulkRenewMessage- The base class for handling bulk renew messages

=head1 DESCRIPTION

The base class for handling Bulk Renew Message

=cut

use strict;
use warnings;

our $VERSION = 3.3;

use Params::Validate qw( :all );
use JSON qw(encode_json decode_json);
use SimpleLookupService::Keywords::KeyNames;
use Carp qw(cluck);

use SimpleLookupService::Utils::Time qw(minutes_to_iso iso_to_minutes is_iso iso_to_unix);


use base 'SimpleLookupService::Message';

sub init {
    my ( $self, @args ) = @_;
    my %parameters = validate( @args, { record_uris => 0, ttl=>0 } );



    if(defined $parameters{record_uris} ){

        if(ref($parameters{record_uris}) eq 'ARRAY' && scalar @{$parameters{record_uris}} < 1){
            cluck "Record uri cannot be empty";
            return -1;
        }

        unless(ref($parameters{record_uris}) eq 'ARRAY'){
            $parameters{record_uris} = [$parameters{record_uris}];
        }

        $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_BULKRENEW_RECORDSURIS)} = $parameters{record_uris};
    }

    if(defined $parameters{ttl}){

        if(ref($parameters{ttl}) eq 'ARRAY' && scalar @{$parameters{ttl}} > 1){
            cluck "Record TTL size cannot be > 1";
            return -1;
        }
        my $tmp;
        if(ref($parameters{ttl}) eq 'ARRAY'){
            $tmp = $parameters{ttl}->[0];
        }else{
            $tmp = $parameters{ttl};
        }

        if(is_iso($tmp)){
            $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_TTL)} = [$tmp];
        }else{
            cluck "Record TTL should be iso";
            return -1;
        }

    }

    return 0;
}


sub getRecordUris {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_BULKRENEW_RECORDSURIS)};
}

sub setRecordUris  {
    my ( $self, $value ) = @_;
    if(ref($value) eq 'ARRAY' && scalar(@{$value}) < 1){
        cluck "Record uris cannot be empty";
        return -1;
    }

    unless (ref($value) eq 'ARRAY'){
        $value  = [$value];
    }
    $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_BULKRENEW_RECORDSURIS)} = $value;
    return 0;
}


sub getRecordTtlAsIso {
    my $self = shift;
    my $value = $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_TTL)}->[0];

    if(defined $value){
        if(is_iso($value)){
            return [$value];

        }else{
            my $tmp = minutes_to_iso($value);

            return [$tmp];
        }
    }

    return undef;

}

sub setRecordTtlAsIso {
    my ( $self, $value ) = @_;

    if(ref($value) eq 'ARRAY' && scalar(@{$value}) > 1){
        cluck "Record Ttl array size cannot be > 1";
        return -1;
    }

    my $ttl = 0;
    if(ref($value) eq 'ARRAY'){
        $ttl = $value->[0];
    }else{
        $ttl = $value;
    }

    if(is_iso($ttl)){
        $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_TTL)} = [$ttl];
    }else{
        cluck "Record Ttl not in ISO 8601 format";
        return -1;
    }

    return 0;
}

sub getRecordTtlInMinutes {
    my $self = shift;
    my $value = $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_TTL)}->[0];

    if(defined $value){
        if(is_iso($value)){
            my $tmp = iso_to_minutes($value);

            return [$tmp];
        }else{
            return [$value];
        }
    }

    return undef;

}


sub setRecordTtlInMinutes {
    my ( $self, $value ) = @_;

    if(ref($value) eq 'ARRAY' && scalar(@{$value}) > 1){
        cluck "Record Ttl array size cannot be > 1";
        return -1;
    }

    my $ttl = 0;
    if(ref($value) eq 'ARRAY'){
        $ttl = $value->[0];
    }else{
        $ttl = $value;
    }

    if(is_iso($ttl)){
        cluck "Record Ttl should be in minutes (integer)";
        return -1;
    }else{

        $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_TTL)} = [minutes_to_iso($ttl)];
    }

    return 0;
}


1;