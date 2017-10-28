package perfSONAR_PS::Client::PSConfig::Groups::Disjoint;

use Mouse;
use JSON;
use perfSONAR_PS::Client::PSConfig::AddressSelectors::AddressSelectorFactory;

extends 'perfSONAR_PS::Client::PSConfig::Groups::BaseP2PGroup';

has 'type' => (
      is      => 'ro',
      default => sub {
          my $self = shift;
          $self->data->{'type'} = 'disjoint';
          return $self->data->{'type'};
      },
  );

sub a_addresses{
    my ($self, $val) = @_;
    return $self->_field_class_factory_list('a-addresses', 
        'perfSONAR_PS::Client::PSConfig::AddressSelectors::BaseAddressSelector', 
        'perfSONAR_PS::Client::PSConfig::AddressSelectors::AddressSelectorFactory', 
        $val);
}

sub add_a_address{
    my ($self, $val) = @_;
    $self->_add_field_class('a-addresses', 'perfSONAR_PS::Client::PSConfig::AddressSelectors::BaseAddressSelector', $val);
}

sub b_addresses{
    my ($self, $val) = @_;
    return $self->_field_class_factory_list('b-addresses', 
        'perfSONAR_PS::Client::PSConfig::AddressSelectors::BaseAddressSelector', 
        'perfSONAR_PS::Client::PSConfig::AddressSelectors::AddressSelectorFactory', 
        $val);
}

sub add_b_address{
    my ($self, $val) = @_;
    $self->_add_field_class('b-addresses', 'perfSONAR_PS::Client::PSConfig::AddressSelectors::BaseAddressSelector', $val);
}



__PACKAGE__->meta->make_immutable;

1;