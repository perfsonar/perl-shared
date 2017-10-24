package perfSONAR_PS::Client::PSConfig::Host;

use Mouse;

extends 'perfSONAR_PS::Client::PSConfig::BaseMetaNode';

sub address_refs{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'addresses'} = $val;
    }
    return $self->data->{'addresses'};
}

sub add_address_ref{
    my ($self, $val) = @_;
    
    unless(defined $val){
        return;
    }
    
    unless($self->data->{'addresses'}){
        $self->data->{'addresses'} = [];
    }

    push @{$self->data->{'addresses'}}, $val;
}

sub archive_refs{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'archives'} = $val;
    }
    return $self->data->{'archives'};
}

sub add_archive_ref{
    my ($self, $val) = @_;
    
    unless(defined $val){
        return;
    }
    
    unless($self->data->{'archives'}){
        $self->data->{'archives'} = [];
    }

    push @{$self->data->{'archives'}}, $val;
}

sub site{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'site'} = $val;
    }
    return $self->data->{'site'};
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


__PACKAGE__->meta->make_immutable;

1;
