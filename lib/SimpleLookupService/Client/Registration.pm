package SimpleLookupService::Client::Registration;

=head1 NAME

SimpleLookupService::Client::Registration - The Lookup Service Registration class

=head1 DESCRIPTION

A base class for Lookup Service registrations. It defines the fields used by all 
registrations. Specific types of service records may become subclasses of this class. It 
allows for any key to be added with the addField function.

=cut

use strict;
use warnings;
use Scalar::Util qw(blessed);

our $VERSION = 3.2;

use Params::Validate qw( :all );
use JSON qw(encode_json decode_json);
use SimpleLookupService::Records::Record;
use SimpleLookupService::Records::RecordFactory;
use SimpleLookupService::Keywords::RecordTypeMapping;

use Data::Dumper;
use base 'SimpleLookupService::Client::SimpleLS';

sub init  {
    my ( $self, @args ) = @_;
    my %parameters = validate( @args, { url => 1, timeout=> 0, record => 0} );
    my $data;
    if(defined $parameters{'record'}){
    	$data = $parameters{'record'}->toJson();
    	return $self->SUPER::init({
           url => $parameters{'url'},
           timeout => $parameters{'timeout'},
           connectionType => 'POST',
           data => $data
    	});
    }else{
    	return $self->SUPER::init({
           url => $parameters{'url'},
           timeout => $parameters{'timeout'},
           connectionType => 'POST',
    	});
    }
    
}

sub register{
	my ($self, $parameter) = @_;
	print Dumper $self;
    if (defined $parameter){
    	
    	$self->_setRecord($parameter);
    }
    
    if(!defined $self->{DATA}){
    	die "Record not defined";
    }
    
    my $result = $self->SUPER::connect();
    
        # Check the outcome of the response
    if ($result->is_success) {
        my $jsonResp = decode_json($result->content);
        #print $jsonResp;
        my $rType = $jsonResp->{'type'}->[0];
        my $resultRecord = SimpleLookupService::Records::RecordFactory->instantiate($rType);
        $resultRecord->fromHashRef($jsonResp);
		return (0, $resultRecord);
    } else {
        return (-1, { message => $result->status_line });
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