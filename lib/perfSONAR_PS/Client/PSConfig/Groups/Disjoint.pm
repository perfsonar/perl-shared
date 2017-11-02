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

sub a_address{
    my ($self, $index, $val) = @_;
    return $self->_field_class_factory_list_item('a-addresses', $index,
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

sub b_address{
    my ($self, $index, $val) = @_;
    return $self->_field_class_factory_list_item('b-addresses', $index,
        'perfSONAR_PS::Client::PSConfig::AddressSelectors::BaseAddressSelector', 
        'perfSONAR_PS::Client::PSConfig::AddressSelectors::AddressSelectorFactory', 
        $val);
}

sub add_b_address{
    my ($self, $val) = @_;
    $self->_add_field_class('b-addresses', 'perfSONAR_PS::Client::PSConfig::AddressSelectors::BaseAddressSelector', $val);
}

sub dimension_size{
    my ($self, $dimension) = @_;
    
    unless(defined $dimension && $dimension < $self->dimension_count()){
        return;
    }  
    
    my $size;
    if($dimension == 0){
        $size = @{$self->data->{'a-addresses'}};
    }else{
        $size = @{$self->data->{'b-addresses'}};
    }

    return $size;
}

sub dimension{
    my ($self, $dimension, $index) = @_;
    
    unless(defined $dimension && $dimension < $self->dimension_count()){
        return;
    }
    
    if($dimension == 0){
        return defined $index ? $self->a_address($index) : $self->a_addresses();
    }
    
    return defined $index ? $self->b_address($index) : $self->b_addresses();
}


__PACKAGE__->meta->make_immutable;

1;