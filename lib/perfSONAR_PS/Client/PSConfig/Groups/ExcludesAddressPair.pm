package perfSONAR_PS::Client::PSConfig::Groups::ExcludesAddressPair;

use Mouse;
use perfSONAR_PS::Client::PSConfig::AddressSelectors::AddressSelectorFactory;

extends 'perfSONAR_PS::Client::PSConfig::BaseNode';

sub local_address{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'local-address'} = $val->data;
    }
    
    my $factory = new perfSONAR_PS::Client::PSConfig::AddressSelectors::AddressSelectorFactory();
    return $factory->build($self->data->{'local-address'});
}

sub target_addresses{
    my ($self, $val) = @_;
    if(defined $val){
        my @tmp_addrs = ();
        foreach my $addr(@{$val}){
            push @tmp_addrs, $addr->data;
        }
        $self->data->{'target-addresses'} = \@tmp_addrs;
    }
    my @tmp_addr_objs = ();
    my $factory = new perfSONAR_PS::Client::PSConfig::AddressSelectors::AddressSelectorFactory();
    foreach my $addr_data(@{$self->data->{'target-addresses'}}){
        push @tmp_addr_objs, $factory->build($addr_data);
    }
    return \@tmp_addr_objs;
}

sub add_target_address{
    my ($self, $val) = @_;
    
    unless(defined $val){
        return;
    }
    
    unless($self->data->{'target-addresses'}){
        $self->data->{'target-addresses'} = [];
    }

    push @{$self->data->{'target-addresses'}}, $val->data;
}

  
__PACKAGE__->meta->make_immutable;

1;