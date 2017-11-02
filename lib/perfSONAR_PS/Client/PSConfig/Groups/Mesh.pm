package perfSONAR_PS::Client::PSConfig::Groups::Mesh;

use Mouse;
use JSON;
use perfSONAR_PS::Client::PSConfig::AddressSelectors::AddressSelectorFactory;

extends 'perfSONAR_PS::Client::PSConfig::Groups::BaseP2PGroup';

has 'type' => (
      is      => 'ro',
      default => sub {
          my $self = shift;
          $self->data->{'type'} = 'mesh';
          return $self->data->{'type'};
      },
  );


sub addresses{
    my ($self, $val) = @_;
    return $self->_field_class_factory_list('addresses', 
        'perfSONAR_PS::Client::PSConfig::AddressSelectors::BaseAddressSelector', 
        'perfSONAR_PS::Client::PSConfig::AddressSelectors::AddressSelectorFactory', 
        $val);
}

sub address{
    my ($self, $index, $val) = @_;
    return $self->_field_class_factory_list_item('addresses', $index,
        'perfSONAR_PS::Client::PSConfig::AddressSelectors::BaseAddressSelector', 
        'perfSONAR_PS::Client::PSConfig::AddressSelectors::AddressSelectorFactory', 
        $val);
}

sub add_address{
    my ($self, $val) = @_;
    $self->_add_field_class('addresses', 'perfSONAR_PS::Client::PSConfig::AddressSelectors::BaseAddressSelector', $val);
}

sub dimension_size{
    my ($self, $dimension) = @_;
    
    unless(defined $dimension && $dimension < $self->dimension_count()){
        return;
    }  
    
    my $size = @{$self->data->{'addresses'}};
    return $size;
}

sub dimension{
    my ($self, $dimension, $index) = @_;
    
    unless(defined $dimension && $dimension < $self->dimension_count()){
        return;
    }

    return defined $index ? $self->address($index) : $self->addresses();
}



__PACKAGE__->meta->make_immutable;

1;