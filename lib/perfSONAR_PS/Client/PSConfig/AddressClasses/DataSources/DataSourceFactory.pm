package perfSONAR_PS::Client::PSConfig::AddressClasses::DataSources::DataSourceFactory;

use Mouse;

use perfSONAR_PS::Client::PSConfig::AddressClasses::DataSources::CurrentConfig;
use perfSONAR_PS::Client::PSConfig::AddressClasses::DataSources::RequestingAgent;

extends 'perfSONAR_PS::Client::PSConfig::BaseNode';

sub build {
    my ($self, $data) = @_;
    
    if($data && exists $data->{'type'}){
        if($data->{'type'} eq 'current-config'){
            return new perfSONAR_PS::Client::PSConfig::AddressClasses::DataSources::CurrentConfig(data => $data);
        }elsif($data->{'type'} eq 'requesting-agent'){
            return new perfSONAR_PS::Client::PSConfig::AddressClasses::DataSources::RequestingAgent(data => $data);
        }
    }
    
    return undef;
    
}

__PACKAGE__->meta->make_immutable;

1;