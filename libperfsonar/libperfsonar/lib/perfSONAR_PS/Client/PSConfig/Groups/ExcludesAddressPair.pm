package perfSONAR_PS::Client::PSConfig::Groups::ExcludesAddressPair;

use Mouse;
use perfSONAR_PS::Client::PSConfig::AddressSelectors::AddressSelectorFactory;

extends 'perfSONAR_PS::Client::PSConfig::BaseNode';

=item local_address()

Get/sets local-address

=cut

sub local_address{
    my ($self, $val) = @_;
    return $self->_field_class_factory('local-address', 
        'perfSONAR_PS::Client::PSConfig::AddressSelectors::BaseAddressSelector', 
        'perfSONAR_PS::Client::PSConfig::AddressSelectors::AddressSelectorFactory', 
        $val);
}

=item target_addresses()

Get/sets target-addresses as an ArrayRef

=cut

sub target_addresses{
    my ($self, $val) = @_;
    return $self->_field_class_factory_list('target-addresses', 
        'perfSONAR_PS::Client::PSConfig::AddressSelectors::BaseAddressSelector', 
        'perfSONAR_PS::Client::PSConfig::AddressSelectors::AddressSelectorFactory', 
        $val);
}

=item target_address()

Get/sets target-address at specified index

=cut

sub target_address{
    my ($self, $index, $val) = @_;
    return $self->_field_class_factory_list_item('target-addresses', $index, 
        'perfSONAR_PS::Client::PSConfig::AddressSelectors::BaseAddressSelector', 
        'perfSONAR_PS::Client::PSConfig::AddressSelectors::AddressSelectorFactory', 
        $val);
}

=item add_target_address()

Adds target-address to list

=cut

sub add_target_address{
    my ($self, $val) = @_;
    $self->_add_field_class('target-addresses', 
        'perfSONAR_PS::Client::PSConfig::AddressSelectors::BaseAddressSelector', 
        $val);
}
  
__PACKAGE__->meta->make_immutable;

1;