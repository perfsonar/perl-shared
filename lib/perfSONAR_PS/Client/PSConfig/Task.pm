package perfSONAR_PS::Client::PSConfig::Task;

use Mouse;

extends 'perfSONAR_PS::Client::PSConfig::BaseMetaNode';

sub group_ref{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'group'} = $val;
    }
    return $self->data->{'group'};
}

sub test_ref{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'test'} = $val;
    }
    return $self->data->{'test'};
}

sub schedule_ref{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'schedule'} = $val;
    }
    return $self->data->{'schedule'};
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

sub tools{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'tools'} = $val;
    }
    return $self->data->{'tools'};
}

sub add_tool{
    my ($self, $val) = @_;
    
    unless(defined $val){
        return;
    }
    
    unless($self->data->{'tools'}){
        $self->data->{'tools'} = [];
    }

    push @{$self->data->{'tools'}}, $val;
}

sub subtask_refs{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'subtasks'} = $val;
    }
    return $self->data->{'subtasks'};
}

sub add_subtask_ref{
    my ($self, $val) = @_;
    
    unless(defined $val){
        return;
    }
    
    unless($self->data->{'subtasks'}){
        $self->data->{'subtasks'} = [];
    }

    push @{$self->data->{'subtasks'}}, $val;
}


sub reference{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'reference'} = $val;
    }
    return $self->data->{'reference'};
}

sub reference_param {
    my ($self, $field, $val) = @_;
    
    unless(defined $field){
        return undef;
    }
    
    if(defined $val){
        $self->_init_field($self->data, 'reference');
        $self->data->{'reference'}->{$field} = $val;
    }
    
    return $self->data->{'reference'}->{$field};
}

sub disabled{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'disabled'} = $val ? JSON::true : JSON::false;
    }
    return $self->data->{'disabled'} ? 1 : 0;
}



__PACKAGE__->meta->make_immutable;

1;
