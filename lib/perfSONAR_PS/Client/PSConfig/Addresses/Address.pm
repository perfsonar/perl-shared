package perfSONAR_PS::Client::PSConfig::Addresses::Address;

use Mouse;
#use perfSONAR_PS::Client::PSConfig::Addresses::RemoteAddress;

extends 'perfSONAR_PS::Client::PSConfig::Addresses::BaseLabelledAddress';

sub host_ref{
    my ($self, $val) = @_;
    return $self->_field_name('host', $val);
}

sub tags{
    my ($self, $val) = @_;
    return $self->_field('tags', $val);
}

sub add_tag{
    my ($self, $val) = @_;
    $self->_add_list_item('tags', $val);
}

sub remote_addresses{
    my ($self, $val) = @_;
    
    return $self->_field_class_map('remote-addresses', 'perfSONAR_PS::Client::PSConfig::Addresses::RemoteAddress', $val);
}

sub remote_address{
    my ($self, $field, $val) = @_;
    
    return $self->_field_class_map_item('remote-addresses', $field, 'perfSONAR_PS::Client::PSConfig::Addresses::RemoteAddress', $val);
} 

sub remote_address_names{
    my ($self) = @_;
    return $self->_get_map_names("remote-addresses");
} 

sub remove_remote_address {
    my ($self, $field) = @_;
    $self->_remove_map_item('remote-addresses', $field);
}




__PACKAGE__->meta->make_immutable;

1;
