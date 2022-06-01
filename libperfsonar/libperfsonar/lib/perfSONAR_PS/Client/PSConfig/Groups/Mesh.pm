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

=item addresses()

Gets/sets addresses as ArrayRef

=cut

sub addresses{
    my ($self, $val) = @_;
    return $self->_field_class_factory_list('addresses', 
        'perfSONAR_PS::Client::PSConfig::AddressSelectors::BaseAddressSelector', 
        'perfSONAR_PS::Client::PSConfig::AddressSelectors::AddressSelectorFactory', 
        $val);
}

=item address()

Gets/sets address at specified index

=cut

sub address{
    my ($self, $index, $val) = @_;
    return $self->_field_class_factory_list_item('addresses', $index,
        'perfSONAR_PS::Client::PSConfig::AddressSelectors::BaseAddressSelector', 
        'perfSONAR_PS::Client::PSConfig::AddressSelectors::AddressSelectorFactory', 
        $val);
}

=item add_address()

Adds address to list

=cut

sub add_address{
    my ($self, $val) = @_;
    $self->_add_field_class('addresses', 'perfSONAR_PS::Client::PSConfig::AddressSelectors::BaseAddressSelector', $val);
}

=item dimension_size()

This is primarily used by next() and won't have much utility outide that. Returns the
length of the addresses list since both dimensions are the same in a mesh.

=cut

sub dimension_size{
    my ($self, $dimension) = @_;
    
    unless(defined $dimension && $dimension < $self->dimension_count()){
        return;
    }  
    
    my $size = @{$self->data->{'addresses'}};
    return $size;
}

=item dimension_step()

This is primarily used by next() and won't have much utility outide that. Given a dimension
and optional index, return item. If no index given returns addresses, otherwise returns 
item at index index in addresses.

=cut

sub dimension_step{
    my ($self, $dimension, $index) = @_;
    
    unless(defined $dimension && $dimension < $self->dimension_count()){
        return;
    }

    return defined $index ? $self->address($index) : $self->addresses();
}

=item dimension()

Return addresses unless dimension count >1, then return undefined

=cut

sub dimension{
    my ($self, $dimension) = @_;
    
    unless(defined $dimension && $dimension < $self->dimension_count()){
        return;
    }

    return $self->addresses();
}


__PACKAGE__->meta->make_immutable;

1;