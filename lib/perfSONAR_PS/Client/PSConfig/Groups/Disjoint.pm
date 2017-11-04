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

has '_merged_addresses' => (is => 'ro', isa => 'ArrayRef|Undef', writer => '_set_merged_addresses', default => sub{[]});
has '_a_address_map' => (is => 'ro', isa => 'HashRef|Undef', writer => '_set_a_address_map', default => sub{{}});
has '_b_address_map' => (is => 'ro', isa => 'HashRef|Undef', writer => '_set_b_address_map', default => sub{{}});
has '_checked_pairs' => (is => 'ro', isa => 'HashRef|Undef', writer => '_set_checked_pairs', default => sub{{}});

sub unidirectional{
    my ($self, $val) = @_;
    return $self->_field_bool('unidirectional', $val);
}

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
    
    my $size = @{$self->_merged_addresses()};

    return $size;
}

sub dimension{
    my ($self, $dimension, $index) = @_;
    
    unless(defined $dimension && $dimension < $self->dimension_count()){
        return;
    }
    
    return defined $index ? $self->_merged_addresses()->[$index] : $self->_merged_addresses();
}

sub _start {
    my ($self) = @_;
    my @merged_addresses = ();
    my %a_addr_map = ();
    my %b_addr_map = ();
    foreach my $a_addr(@{$self->a_addresses()}){
        push @merged_addresses, $a_addr;
        $a_addr_map{$a_addr->checksum()} = 1;
        
    }
    foreach my $b_addr(@{$self->b_addresses()}){
        push @merged_addresses, $b_addr;
        $b_addr_map{$b_addr->checksum()} = 1;
        
    }
    $self->_set_merged_addresses(\@merged_addresses);
    $self->_set_a_address_map(\%a_addr_map);
    $self->_set_b_address_map(\%b_addr_map);
    $self->_set_checked_pairs({});
    
    return;
}

sub _stop {
    my ($self) = @_;
    $self->_set_merged_addresses(undef);
    $self->_set_a_address_map(undef);
    $self->_set_b_address_map(undef);
    $self->_set_checked_pairs(undef);
    $self->_set_exclude_checksum_map(undef);
}

sub is_excluded_selectors {
    my ($self, $addr_sels) = @_;
    
    #validate
    unless($addr_sels && ref $addr_sels eq 'ARRAY' && @{$addr_sels} == 2){
        return;
    }
    
    #verify that we haven't already checked this
    my $checksum0 = $addr_sels->[0]->checksum();
    my $checksum1 = $addr_sels->[1]->checksum();
    if($self->_checked_pairs()->{"$checksum0->$checksum1"}){
        return 1;
    }
    
    #check that first is in a and the other is in b, if bidirectional also ok if reverse
    unless(
        ($self->_a_address_map()->{$checksum0} && $self->_b_address_map()->{$checksum1}) ||
        (!$self->unidirectional() && $self->_a_address_map()->{$checksum1} && $self->_b_address_map()->{$checksum0})
    ){
        return 1;
    }
    $self->_checked_pairs()->{"$checksum0->$checksum1"} = 1;
    
    return $self->SUPER::is_excluded_selectors($addr_sels);;
}



__PACKAGE__->meta->make_immutable;

1;