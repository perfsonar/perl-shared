package perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::BaseOperandFilter;

use Mouse;
use perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::FilterFactory;

extends 'perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::BaseFilter';

sub filters{
    my ($self, $val) = @_;
    return $self->_field_class_factory_list('filters', 
        'perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::BaseFilter', 
        'perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::FilterFactory', 
        $val);
}

sub add_filter{
    my ($self, $val) = @_;
    $self->_add_field_class('filters', 'perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::BaseFilter', $val);
}

__PACKAGE__->meta->make_immutable;

1;