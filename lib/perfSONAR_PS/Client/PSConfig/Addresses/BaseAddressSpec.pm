package perfSONAR_PS::Client::PSConfig::Addresses::BaseAddressSpec;

use Mouse;
use JSON;

extends 'perfSONAR_PS::Client::PSConfig::BaseMetaNode';

sub address{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'address'} = $val;
    }
    return $self->data->{'address'};
}

sub agent_bind_address{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'agent_bind_address'} = $val;
    }
    return $self->data->{'agent_bind_address'};
}

sub lead_bind_address{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'lead_bind_address'} = $val;
    }
    return $self->data->{'lead_bind_address'};
}

sub pscheduler_address{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'pscheduler_address'} = $val;
    }
    return $self->data->{'pscheduler_address'};
}

sub disabled{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'disabled'} = $val ? JSON::true : JSON::false;
    }
    return $self->data->{'disabled'} ? 1 : 0;
}

sub no_agent{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'no-agent'} = $val ? JSON::true : JSON::false;
    }
    return $self->data->{'no-agent'} ? 1 : 0;
}

sub context_refs{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'contexts'} = $val;
    }
    return $self->data->{'contexts'};
}

sub add_context_ref{
    my ($self, $val) = @_;
    
    unless(defined $val){
        return;
    }
    
    unless($self->data->{'contexts'}){
        $self->data->{'contexts'} = [];
    }

    push @{$self->data->{'contexts'}}, $val;
}


__PACKAGE__->meta->make_immutable;

1;
