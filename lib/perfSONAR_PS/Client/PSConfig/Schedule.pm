package perfSONAR_PS::Client::PSConfig::Schedule;

use Mouse;

extends 'perfSONAR_PS::Client::PSConfig::BaseMetaNode';

sub start{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'start'} = $val;
    }
    return $self->data->{'start'};
}

sub slip{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'slip'} = $val;
    }
    return $self->data->{'slip'};
}

sub sliprand{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'sliprand'} = $val ? JSON::true : JSON::false;
    }
    return $self->data->{'sliprand'} ? 1 : 0;
}

sub repeat{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'repeat'} = $val;
    }
    return $self->data->{'repeat'};
}

sub until{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'until'} = $val;
    }
    return $self->data->{'until'};
}

sub max_runs{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'max-runs'} = $val;
    }
    return $self->data->{'max-runs'};
}


__PACKAGE__->meta->make_immutable;

1;
