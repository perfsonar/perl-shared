package SimpleLookupService::Message;
use strict;
use warnings;


=head1 NAME

SimpleLookupService::Message - The base class for Lookup Service Messages

=head1 DESCRIPTION

A base class for Lookup Service messages. It defines a simple key-value structure and has some utility methods

=cut

use fields 'RECORD_HASH';
use Carp qw(cluck);
use JSON qw( encode_json decode_json to_json);

sub new{
    my $package = shift;

    my $self = fields::new( $package );

    return $self;
}


sub init {
    my ($self, @args) = @_;
    return 0;
}


sub getRecordHash {
    my $self = shift;
    return $self->{RECORD_HASH};
}

sub toJson(){
    my $self = shift;

    if(defined $self->getRecordHash()){
        my $json = to_json($self->getRecordHash(),{ canonical => 1, utf8 => 1 });
        return $json;
    }else{
        return undef;
    }

}

#creates record object from json
sub fromJson(){
    my ($self, $jsonData) = @_;

    if(defined $jsonData && $jsonData ne ''){
        my $perlDS = decode_json($jsonData);
        $self->fromHashRef($perlDS);
        return 0;
    }else{
        cluck "Error creating record. empty data";
        return -1;
    }

}

#creates record object from perl data structure
sub fromHashRef(){
    my ($self, $perlDS) = @_;

    if(defined $perlDS){
        foreach my $key (keys %{$perlDS}){
            $self->{RECORD_HASH}->{$key} = ${perlDS}->{$key};
        }
    }else{
        cluck "Error creating record. Empty hash";
        return -1;
    }


    return 0;
}


1;