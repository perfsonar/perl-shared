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

sub archive_refs{
    my ($self, $val) = @_;
    return $self->_field_refs('archives', $val);
}

sub add_archive_ref{
    my ($self, $val) = @_;
    $self->_add_field_ref('archives', $val);
}



__PACKAGE__->meta->make_immutable;

1;
