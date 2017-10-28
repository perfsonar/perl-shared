package perfSONAR_PS::Client::PSConfig::Subtask;

use Mouse;
use perfSONAR_PS::Client::PSConfig::ScheduleOffset;

extends 'perfSONAR_PS::Client::PSConfig::BaseMetaNode';

sub test_ref{
    my ($self, $val) = @_;
    return $self->_field_name('test', $val);
}

sub schedule_offset{
    my ($self, $val) = @_;
    return $self->_field_class('schedule-offset', 'perfSONAR_PS::Client::PSConfig::ScheduleOffset', $val);
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
