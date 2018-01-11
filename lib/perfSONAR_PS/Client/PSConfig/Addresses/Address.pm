package perfSONAR_PS::Client::PSConfig::Addresses::Address;

use Mouse;
#use perfSONAR_PS::Client::PSConfig::Addresses::RemoteAddress;

extends 'perfSONAR_PS::Client::PSConfig::Addresses::BaseLabelledAddress';

=item host_ref()

Gets/sets the host

=cut

sub host_ref{
    my ($self, $val) = @_;
    return $self->_field_name('host', $val);
}

=item tags()

Gets/sets the tags as an ArrayRef

=cut

sub tags{
    my ($self, $val) = @_;
    return $self->_field('tags', $val);
}

=item add_tag()

Adds a tag to the list

=cut

sub add_tag{
    my ($self, $val) = @_;
    $self->_add_list_item('tags', $val);
}

=item remote_addresses()

Gets/sets remote-addresses as HashRef of RemoteAddress objects

=cut

sub remote_addresses{
    my ($self, $val) = @_;
    
    return $self->_field_class_map('remote-addresses', 'perfSONAR_PS::Client::PSConfig::Addresses::RemoteAddress', $val);
}

=item remote_address()

Gets/sets remote-address specified by field

=cut

sub remote_address{
    my ($self, $field, $val) = @_;
    
    return $self->_field_class_map_item('remote-addresses', $field, 'perfSONAR_PS::Client::PSConfig::Addresses::RemoteAddress', $val);
} 

=item remote_address_names()

Gets the list of keys  found in remote-address HashRef

=cut

sub remote_address_names{
    my ($self) = @_;
    return $self->_get_map_names("remote-addresses");
} 

=item remove_remote_address()

Removes the remote-address specified by field

=cut

sub remove_remote_address {
    my ($self, $field) = @_;
    $self->_remove_map_item('remote-addresses', $field);
}




__PACKAGE__->meta->make_immutable;

1;
