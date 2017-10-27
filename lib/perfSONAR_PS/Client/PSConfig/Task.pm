package perfSONAR_PS::Client::PSConfig::Task;

use Mouse;

extends 'perfSONAR_PS::Client::PSConfig::BaseMetaNode';

sub group_ref{
    my ($self, $val) = @_;
    return $self->_field('group', $val);
}

sub test_ref{
    my ($self, $val) = @_;
    return $self->_field('test', $val);
}

sub schedule_ref{
    my ($self, $val) = @_;
    return $self->_field('schedule', $val);
}

sub archive_refs{
    my ($self, $val) = @_;
    return $self->_field('archives', $val);
}

sub add_archive_ref{
    my ($self, $val) = @_;
    $self->_add_list_item('archives', $val);
}

sub tools{
    my ($self, $val) = @_;
    return $self->_field('tools', $val);
}

sub add_tool{
    my ($self, $val) = @_;
    $self->_add_list_item('tools', $val);
}

sub subtask_refs{
    my ($self, $val) = @_;
    return $self->_field('subtasks', $val);
}

sub add_subtask_ref{
    my ($self, $val) = @_;
    $self->_add_list_item('subtasks', $val);
}


sub reference{
    my ($self, $val) = @_;
    return $self->_field('reference', $val);
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
    return $self->_field_bool('disabled', $val);
}



__PACKAGE__->meta->make_immutable;

1;
