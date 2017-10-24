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
    if(defined $val){
        my @tmp_addrs = ();
        foreach my $addr(@{$val}){
            push @tmp_addrs, $addr->data;
        }
        $self->data->{'a-addresses'} = \@tmp_addrs;
    }
    my @tmp_addr_objs = ();
    my $factory = new perfSONAR_PS::Client::PSConfig::AddressSelectors::AddressSelectorFactory();
    foreach my $addr_data(@{$self->data->{'a-addresses'}}){
        push @tmp_addr_objs, $factory->build($addr_data);
    }
    return \@tmp_addr_objs;
}

sub add_a_address{
    my ($self, $val) = @_;
    
    unless(defined $val){
        return;
    }
    
    unless($self->data->{'a-addresses'}){
        $self->data->{'a-addresses'} = [];
    }

    push @{$self->data->{'a-addresses'}}, $val->data;
}

sub b_addresses{
    my ($self, $val) = @_;
    if(defined $val){
        my @tmp_addrs = ();
        foreach my $addr(@{$val}){
            push @tmp_addrs, $addr->data;
        }
        $self->data->{'b-addresses'} = \@tmp_addrs;
    }
    my @tmp_addr_objs = ();
    my $factory = new perfSONAR_PS::Client::PSConfig::AddressSelectors::AddressSelectorFactory();
    foreach my $addr_data(@{$self->data->{'b-addresses'}}){
        push @tmp_addr_objs, $factory->build($addr_data);
    }
    return \@tmp_addr_objs;
}

sub add_b_address{
    my ($self, $val) = @_;
    
    unless(defined $val){
        return;
    }
    
    unless($self->data->{'b-addresses'}){
        $self->data->{'b-addresses'} = [];
    }

    push @{$self->data->{'b-addresses'}}, $val->data;
}


__PACKAGE__->meta->make_immutable;

1;