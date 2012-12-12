package SimpleLookupService::Client::RecordManager;

=head1 NAME

SimpleLookupService::Client::RecordManager - The Lookup Service RecordManager class

=head1 DESCRIPTION

A class to manage/edit Lookup Service records. 

=cut

use strict;
use warnings;
use Scalar::Util qw(blessed);

our $VERSION = 3.2;

use Params::Validate qw( :all );
use JSON qw(encode_json decode_json);
use SimpleLookupService::Records::Record;

use Data::Dumper;
use base 'SimpleLookupService::Client::SimpleLS';


sub init  {
    my ( $self, @args ) = @_;
    my %parameters = validate( @args, { url => 1, timeout=> 0} );
    my $data;
    return $self->SUPER::init({
           url => $parameters{'url'},
           timeout => $parameters{'timeout'}
    	});
    
    
}

sub renew{
	
	my ($self, $ttl) = @_;
	if (defined $ttl){
		my $record = SimpleLookupService::Records::Network::Record->new();
		$record->init(ttl=>$ttl);
    	$self->_setRecord($record);
    }
	$self->SUPER::setConnectionType({connectionType => 'POST'});
	my $result = $self->SUPER::connect();
	 if ($result->is_success) {
        my $jsonResp = decode_json($result->content);
        my $rType = $jsonResp->{'type'}->[0];
        my $resultRecord = SimpleLookupService::Records::RecordFactory->instantiate($rType);
        $resultRecord->fromHashRef($jsonResp);
		return (0, $resultRecord);
        #print $result->content;
        #return (0, $jsonResp);
    } else {
        return (-1, { message => $result->status_line });
    }
}

sub delete{
	my $self = shift;
	$self->SUPER::setConnectionType({connectionType => 'DELETE' });
	my $result = $self->SUPER::connect();
	 if ($result->is_success) {
        my $jsonResp = decode_json($result->content);
        my $rType = $jsonResp->{'type'}->[0];
        my $resultRecord = SimpleLookupService::Records::RecordFactory->instantiate($rType);
        $resultRecord->fromHashRef($jsonResp);
		return (0, $resultRecord);
        #print $result->content;
        #return (0, $jsonResp);
    } else {
        return (-1, { message => $result->status_line });
    }
}

sub getRecord{
	my $self = shift;
	$self->SUPER::setConnectionType({connectionType => 'GET'});
	my $result = $self->SUPER::connect();
	 if ($result->is_success) {
        my $jsonResp = decode_json($result->content);
        #print $result->content;
        #return (0, $jsonResp);
        my $rType = $jsonResp->{'type'}->[0];
        my $resultRecord = SimpleLookupService::Records::RecordFactory->instantiate($rType);
        $resultRecord->fromHashRef($jsonResp);
		return (0, $resultRecord);
    } else {
        return (-1, { message => $result->status_line });
    }
}


sub getKeyInRecord{
	
	my ($self, $key) = @_;
    
    if(defined $key){
    	my $modifiedUrl = $self->SUPER::getUrl();
    	$modifiedUrl .= "/".$key;
    
   	 	$self->SUPER::setUrl({'url' => $modifiedUrl});
    
    	my $result = getRecord();
    	return $result;
    }else{
    	return (-1, { message => "key not defined"});
    }
   
}


sub _setRecord{
	my ($self, $record) = @_;
	if($record->isa('SimpleLookupService::Records::Record')){
		my $data = $record->toJson();
		$self->SUPER::setData({data => $data});
	}else{
		die "Record should be of type SimpleLookupService::Records::Record or its subclass ";
	}
	
}