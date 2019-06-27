package SimpleLookupService::Client::BulkRenewManager;

=head1 NAME

SimpleLookupService::Client::BulkRenewManager - The Lookup Service Bulk Renew Manager

=head1 DESCRIPTION

This handles bulk renewal of record ids.

=cut
use strict;
use warnings;

use Scalar::Util qw(blessed);

use Carp qw(cluck);
use Params::Validate qw( :all );
use JSON qw(encode_json decode_json);
use SimpleLookupService::BulkRenewResponse;

use fields 'SERVER', 'MESSAGE';

our $VERSION = 3.3;

sub new {
    my $package = shift;

    my $self = fields::new( $package );

    return $self;
}

sub init  {
    my ( $self, @args ) = @_;
    my %parameters = validate( @args, { server => 1, message => 0} );

    my $server = $parameters{server};
    if(! $server->isa('SimpleLookupService::Client::SimpleLS')){
        cluck "Error initializing client. Server is not SimpleLookupService::Client::SimpleLS server";
        return -1;
    }

    $self->{SERVER} = $server;
    $self->{SERVER}->connect();

    $self->{SERVER}->setConnectionType('PUT');



    if (defined $parameters{'message'}){
        my $r = $self->_setMessage($parameters{'message'});
        if($r != 0){
            cluck "Error initializing client. Bulk renew message could not be set.";
            return -1;
        }
    }

    return 0;

}


sub renew{
    my ($self, $parameter) = @_;
    #print Dumper $self;
    if (defined $parameter){
        $self->_setMessage($parameter);
    }


    if(!defined $self->{MESSAGE}){
        cluck "Bulk renew message not defined";
        return -1;
    }

    my $res = $self->{SERVER}->setData($self->{MESSAGE}->toJson());

    if($res<0){
        cluck "Error setting data";
        return -1;
    }

    my $result = $self->{SERVER}->send(resourceLocator=>"lookup/records");

    # Check the outcome of the response
    if ($result->is_success) {
        my $response = SimpleLookupService::BulkRenewResponse->new();
        $response->fromJson($result->body);
        $response->validate();
        return(0, $response);
    } else {
        return (-1, { message => $result->get_start_line_chunk(0) });
    }

}


sub _setMessage{
    my ($self, $message) = @_;
    if($message->isa('SimpleLookupService::BulkRenewMessage')){

        $self->{MESSAGE} = $message;
    }else{
        cluck "Message should be of type SimpleLookupService::BulkRenewMessage or its subclass ";
        return -1;

    }

    return 0;

}

1;