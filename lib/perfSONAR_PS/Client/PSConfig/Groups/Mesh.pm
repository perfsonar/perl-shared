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
    if(defined $val){
        my @tmp_addrs = ();
        foreach my $addr(@{$val}){
            push @tmp_addrs, $addr->data;
        }
        $self->data->{'addresses'} = \@tmp_addrs;
    }
    my @tmp_addr_objs = ();
    my $factory = new perfSONAR_PS::Client::PSConfig::AddressSelectors::AddressSelectorFactory();
    foreach my $addr_data(@{$self->data->{'addresses'}}){
        push @tmp_addr_objs, $factory->build($addr_data);
    }
    return \@tmp_addr_objs;
}

sub add_address{
    my ($self, $val) = @_;
    
    unless(defined $val){
        return;
    }
    
    unless($self->data->{'addresses'}){
        $self->data->{'addresses'} = [];
    }

    push @{$self->data->{'addresses'}}, $val->data;
}


__PACKAGE__->meta->make_immutable;

1;