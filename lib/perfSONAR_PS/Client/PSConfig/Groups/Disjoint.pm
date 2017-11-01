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

sub next{
    my ($self) = @_;
    
    #TODO: Can we generalize this to infinite dimensions?
    #TODO: how do we handle exclusions in a general way?
    my $a_size = @{$self->data->{'a-addresses'}}; #use data directly for efficiency
    my $b_size = @{$self->data->{'b-addresses'}};
    my $a_index = int($self->iter() / $b_size);
    my $b_index = int($self->iter() % $b_size);
    
    print "$a_index, $b_index\n";
    #check the bounds
    if($a_index >= $a_size){
        #we reached the end
        return;
    }elsif($b_index >= $b_size){
        #this should never happen
        $self->_set_error("Tried to access b-address at $b_index but only $b_size items. This is likely a bug.");
        return;
    }
    
    #increment and return the pair
    $self->_increment_iter();
    return ($self->a_address($a_index), $self->b_address($b_index));
}



__PACKAGE__->meta->make_immutable;

1;