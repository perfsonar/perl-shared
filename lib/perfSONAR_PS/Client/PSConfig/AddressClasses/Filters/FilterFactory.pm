package perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::FilterFactory;

use Mouse;

use perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::AddressClass;
use perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::And;
use perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::Host;
use perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::IPVersion;
use perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::Netmask;
use perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::Not;
use perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::Or;
use perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::Tag;

extends 'perfSONAR_PS::Client::PSConfig::BaseNode';

sub build {
    my ($self, $data) = @_;
    
    if($data && exists $data->{'type'}){
        if($data->{'type'} eq 'address-class'){
            return new perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::AddressClass(data => $data);
        }elsif($data->{'type'} eq 'and'){
            return new perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::And(data => $data);
        }elsif($data->{'type'} eq 'host'){
            return new perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::Host(data => $data);
        }elsif($data->{'type'} eq 'ip-version'){
            return new perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::IPVersion(data => $data);
        }elsif($data->{'type'} eq 'netmask'){
            return new perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::Netmask(data => $data);
        }elsif($data->{'type'} eq 'not'){
            return new perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::Not(data => $data);
        }elsif($data->{'type'} eq 'or'){
            return new perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::Or(data => $data);
        }elsif($data->{'type'} eq 'tag'){
            return new perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::Tag(data => $data);
        }
    }
        
    return undef;
    
}

__PACKAGE__->meta->make_immutable;

1;