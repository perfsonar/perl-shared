package perfSONAR_PS::Client::PSConfig::Groups::List;

use Mouse;
use JSON;
use perfSONAR_PS::Client::PSConfig::AddressSelectors::AddressSelectorFactory;

extends 'perfSONAR_PS::Client::PSConfig::Groups::BaseGroup';

has 'type' => (
      is      => 'ro',
      default => sub {
          my $self = shift;
          $self->data->{'type'} = 'list';
          return $self->data->{'type'};
      },
  );

=item dimension_count()

Returns 1 since there is only one dimension in a list

=cut

sub dimension_count{
    return 1;
}

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
length of the addresses list. Provided dimension must always be 0 since there is only
1 dimension.

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

Return addresses unless dimension count >0, then return undefined

=cut

sub dimension{
    my ($self, $dimension) = @_;
    
    unless(defined $dimension && $dimension < $self->dimension_count()){
        return;
    }

    return $self->addresses();
}

=item select_addresses()

Given a name/label/address HashRefs, returns the Address object in a single-item list.

=cut

sub select_addresses{
    my ($self, $addr_nlas) = @_;
    
    #validate
    unless($addr_nlas && ref $addr_nlas eq 'ARRAY' && @{$addr_nlas} == 1){
        return;
    }
    
    my @addresses = ();
    foreach my $addr_nla(@{$addr_nlas->[0]}){
         my $selected_addr = $self->select_address(
                $addr_nla->{'address'}, 
                $addr_nla->{'label'}, 
                $addr_nla->{'name'}
            );
        push @addresses, [$selected_addr] if($selected_addr);
    }
    
    return \@addresses;
}


__PACKAGE__->meta->make_immutable;

1;