package perfSONAR_PS::Client::PSConfig::Task;

use Mouse;

extends 'perfSONAR_PS::Client::PSConfig::BaseMetaNode';

sub scheduled_by{
    my ($self, $val) = @_;
    return $self->_field_intzero('scheduled-by', $val);
}

sub group_ref{
    my ($self, $val) = @_;
    return $self->_field_name('group', $val);
}

sub test_ref{
    my ($self, $val) = @_;
    return $self->_field_name('test', $val);
}

sub schedule_ref{
    my ($self, $val) = @_;
    return $self->_field_name('schedule', $val);
}

sub archive_refs{
    my ($self, $val) = @_;
    return $self->_field_refs('archives', $val);
}

sub add_archive_ref{
    my ($self, $val) = @_;
    $self->_add_field_ref('archives', $val);
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
    return $self->_field_refs('subtasks', $val);
}

sub add_subtask_ref{
    my ($self, $val) = @_;
    $self->_add_field_ref('subtasks', $val);
}

sub reference{
    my ($self, $val) = @_;
    return $self->_field_anyobj('reference', $val);
}

sub reference_param{
    my ($self, $field, $val) = @_;    
    return $self->_field_anyobj_param('reference', $field, $val);
}

sub disabled{
    my ($self, $val) = @_;
    return $self->_field_bool('disabled', $val);
}



__PACKAGE__->meta->make_immutable;

1;
