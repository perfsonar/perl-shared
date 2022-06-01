package perfSONAR_PS::Client::PScheduler::Run;

use Mouse;
extends 'perfSONAR_PS::Client::PScheduler::BaseNode';

sub start_time{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'start-time'} = $val;
    }
    return $self->data->{'start-time'};
}

sub end_time{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'end-time'} = $val;
    }
    return $self->data->{'end-time'};
}


sub state{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'state'} = $val;
    }
    return $self->data->{'state'};
}

sub duration{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'duration'} = $val;
    }
    return $self->data->{'duration'};
}

sub state_display{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'state-display'} = $val;
    }
    return $self->data->{'state-display'};
}

sub participant{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'participant'} = $val;
    }
    return $self->data->{'participant'};
}

sub participants{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'participants'} = $val;
    }
    return $self->data->{'participants'};
}

sub participant_data{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'participant-data'} = $val;
    }
    return $self->data->{'participant-data'};
}

sub participant_data_full{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'participant-data-full'} = $val;
    }
    return $self->data->{'participant-data-full'};
}

sub errors{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'errors'} = $val;
    }
    return $self->data->{'errors'};
}

sub result_merged{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'result-merged'} = $val;
    }
    return $self->data->{'result-merged'};
}

sub result_full{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'result-full'} = $val;
    }
    return $self->data->{'result-full'};
}


sub result{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'result-full'} = $val;
    }
    return $self->data->{'result-full'};
}


__PACKAGE__->meta->make_immutable;

1;