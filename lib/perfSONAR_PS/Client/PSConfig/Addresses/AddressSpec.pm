package perfSONAR_PS::Client::PSConfig::Addresses::AddressSpec;

use Mouse;
#use perfSONAR_PS::Client::PSConfig::Addresses::RemoteAddressSpec;

extends 'perfSONAR_PS::Client::PSConfig::Addresses::BaseLabelledAddressSpec';

sub host_ref{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'host'} = $val;
    }
    return $self->data->{'host'};
}

sub tags{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'tags'} = $val;
    }
    return $self->data->{'tags'};
}

sub add_tag{
    my ($self, $val) = @_;
    
    unless(defined $val){
        return;
    }
    
    unless($self->data->{'tags'}){
        $self->data->{'tags'} = [];
    }

    push @{$self->data->{'tags'}}, $val;
}

sub remote_addresses{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->data->{'remote-addresses'} = {};
        foreach my $v(keys %{$val}){
            my $tmp_ra = $val->{$v}->data;
            $self->data->{'remote-addresses'}->{$v} = $tmp_ra;
        }
    }
    
    my %remote_addresses = ();
    foreach my $ra(keys %{$self->data->{'remote-addresses'}}){
        my $tmp_ra_obj = $self->remote_address($ra);
        $remote_addresses{$ra} = $tmp_ra_obj;
    }
    
    return \%remote_addresses;
}

sub remote_address{
    my ($self, $field, $val) = @_;
    
    unless(defined $field){
        return undef;
    }
    
    if(defined $val){
        $self->_init_field($self->data, 'remote-addresses');
        $self->data->{'remote-addresses'}->{$field} = $val->data;
    }
    
    unless($self->_has_field($self->data, "remote-addresses")){
        return undef;
    }
    
    unless($self->_has_field($self->data->{'remote-addresses'}, $field)){
        return undef;
    }
    
    return new perfSONAR_PS::Client::PSConfig::Addresses::RemoteAddressSpec(
            data => $self->data->{'remote-addresses'}->{$field}
        );
} 

sub remote_address_names{
    my ($self) = @_;
    return $self->_get_map_names("remote-addresses");
} 

sub remove_remote_address {
    my ($self, $field) = @_;
    $self->_remove_map_item('remote-addresses', $field);
}




__PACKAGE__->meta->make_immutable;

1;
