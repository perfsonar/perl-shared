package perfSONAR_PS::Client::PSConfig::Addresses::BaseLabelledAddress;

use Mouse;
use perfSONAR_PS::Client::PSConfig::Addresses::AddressLabel;

extends 'perfSONAR_PS::Client::PSConfig::Addresses::BaseAddress';

=item labels()

Gets/sets labels as HashRef of AddressLabel objects

=cut

sub labels{
    my ($self, $val) = @_;
    
    return $self->_field_class_map('labels', 'perfSONAR_PS::Client::PSConfig::Addresses::AddressLabel', $val);
}

=item label()

Gets/sets label specified by field 

=cut

sub label{
    my ($self, $field, $val) = @_;
    
    return $self->_field_class_map_item('labels', $field, 'perfSONAR_PS::Client::PSConfig::Addresses::AddressLabel', $val);
}

=item label_names()

Gets the keys in the label HashRef

=cut

sub label_names{
    my ($self) = @_;
    return $self->_get_map_names("labels");
} 

=item remove_label()

Removes label specified by field

=cut

sub remove_label {
    my ($self, $field) = @_;
    $self->_remove_map_item('labels', $field);
}

__PACKAGE__->meta->make_immutable;

1;