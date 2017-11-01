package perfSONAR_PS::Client::PSConfig::AddressSelectors::AddressSelectorFactory;

use Mouse;
use perfSONAR_PS::Client::PSConfig::AddressSelectors::NameLabel;
use perfSONAR_PS::Client::PSConfig::AddressSelectors::Class;

extends 'perfSONAR_PS::Client::PSConfig::BaseNode';

sub build {
    my ($self, $data) = @_;
    
    if($data){
        if(exists $data->{'name'} &&  $data->{'name'}){
            return new perfSONAR_PS::Client::PSConfig::AddressSelectors::NameLabel(data => $data);
        }elsif(exists $data->{'class'} &&  $data->{'class'}){
            return new perfSONAR_PS::Client::PSConfig::AddressSelectors::Class(data => $data);
        }
    }
        
    return undef;
    
}

__PACKAGE__->meta->make_immutable;

1;