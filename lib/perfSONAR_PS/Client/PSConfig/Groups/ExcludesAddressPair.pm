package perfSONAR_PS::Client::PSConfig::Groups::ExcludesAddressPair;

use Mouse;
use perfSONAR_PS::Client::PSConfig::AddressSelectors::AddressSelectorFactory;

extends 'perfSONAR_PS::Client::PSConfig::BaseNode';

sub local_address{
    my ($self, $val) = @_;
    return $self->_field_class_factory('local-address', 
        'perfSONAR_PS::Client::PSConfig::AddressSelectors::BaseAddressSelector', 
        'perfSONAR_PS::Client::PSConfig::AddressSelectors::AddressSelectorFactory', 
        $val);
}

sub target_addresses{
    my ($self, $val) = @_;
    return $self->_field_class_factory_list('target-addresses', 
        'perfSONAR_PS::Client::PSConfig::AddressSelectors::BaseAddressSelector', 
        'perfSONAR_PS::Client::PSConfig::AddressSelectors::AddressSelectorFactory', 
        $val);
}

sub add_target_address{
    my ($self, $val) = @_;
    $self->_add_field_class('target-addresses', 
        'perfSONAR_PS::Client::PSConfig::AddressSelectors::BaseAddressSelector', 
        $val);
}
  
__PACKAGE__->meta->make_immutable;

1;