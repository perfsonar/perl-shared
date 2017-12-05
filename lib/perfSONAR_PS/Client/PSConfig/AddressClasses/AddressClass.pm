package perfSONAR_PS::Client::PSConfig::AddressClasses::AddressClass;

use Mouse;
use perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::FilterFactory;
use perfSONAR_PS::Client::PSConfig::AddressClasses::DataSources::DataSourceFactory;

extends 'perfSONAR_PS::Client::PSConfig::BaseMetaNode';


sub data_source{
    my ($self, $val) = @_;
    return $self->_field_class_factory('data-source', 
        'perfSONAR_PS::Client::PSConfig::AddressClasses::DataSources::BaseDataSource',
        'perfSONAR_PS::Client::PSConfig::AddressClasses::DataSources::DataSourceFactory', 
        $val);
}

sub match_filter{
    my ($self, $val) = @_;
    return $self->_field_class_factory('match-filter', 
        'perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::BaseFilter', 
        'perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::FilterFactory', 
        $val);
}

sub exclude_filter{
    my ($self, $val) = @_;
    return $self->_field_class_factory('exclude-filter', 
        'perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::BaseFilter', 
        'perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::FilterFactory', 
        $val);
}

sub select{
    my ($self, $psconfig) = @_;
    
    #make sure we have a config
    unless($psconfig){
        return (undef, undef);
    }
    
    #make sure we have a data source
    my $data_source = $self->data_source();
    unless($data_source){
        return (undef, undef);
    }
    #start off be selecting everything from data source
    my $ds_addrs = $data_source->fetch($psconfig);
    
    #prune down to only those that match and are not in exclude filter
    my @matching_nlas = ();
    foreach my $ds_addr_name(keys %{$ds_addrs}){
        my $address = $ds_addrs->{$ds_addr_name};
        #skip if gets filtered out
        next unless($self->matches($address, $psconfig));
        #filters did not reject, include
        push @matching_nlas, {'name' => $ds_addr_name, 'address' => $address};
    }

    return \@matching_nlas;
}

sub matches{
    my ($self, $address, $psconfig) = @_;
    
    #get filters
    my $match_filter = $self->match_filter();
    my $exclude_filter = $self->exclude_filter();
    
    #doesn't match match filter, exclude
    if($match_filter && !$match_filter->matches($address, $psconfig)){
        return 0;
    }
    #if does match exclude filter, exlude
    if($exclude_filter && $exclude_filter->matches($address, $psconfig)){
        return 0;
    }
    
    #filters did not reject, include
    return 1;
    
}



__PACKAGE__->meta->make_immutable;

1;
