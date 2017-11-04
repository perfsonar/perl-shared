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

sub dimension_count{
    return 1;
}

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

sub select_addresses{
    my ($self, $addr_nlas) = @_;
    
    #validate
    unless($addr_nlas && ref $addr_nlas eq 'ARRAY' && @{$addr_nlas} == 1){
        return;
    }
    
    my @addresses = ();
    foreach my $addr_nla(@{$addr_nlas->[0]}){
        push @addresses, [$addr_nla->{'address'}];
    }
    
    return \@addresses;
}


__PACKAGE__->meta->make_immutable;

1;