package perfSONAR_PS::Client::PSConfig::Addresses::BaseLabelledAddress;

use Mouse;
use perfSONAR_PS::Client::PSConfig::Addresses::AddressLabel;

extends 'perfSONAR_PS::Client::PSConfig::Addresses::BaseAddress';

sub labels{
    my ($self, $val) = @_;
    
    return $self->_field_class_map('labels', 'perfSONAR_PS::Client::PSConfig::Addresses::AddressLabel', $val);
}

sub label{
    my ($self, $field, $val) = @_;
    
    return $self->_field_class_map_item('labels', $field, 'perfSONAR_PS::Client::PSConfig::Addresses::AddressLabel', $val);
}

sub label_names{
    my ($self) = @_;
    return $self->_get_map_names("labels");
} 

sub remove_label {
    my ($self, $field) = @_;
    $self->_remove_map_item('labels', $field);
}

__PACKAGE__->meta->make_immutable;

1;