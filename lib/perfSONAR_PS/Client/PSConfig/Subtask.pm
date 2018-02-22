package perfSONAR_PS::Client::PSConfig::Subtask;

use Mouse;
use perfSONAR_PS::Client::PSConfig::ScheduleOffset;

extends 'perfSONAR_PS::Client::PSConfig::BaseMetaNode';

=item test_ref()

Gets/sets test as ArrayRef

=cut

sub test_ref{
    my ($self, $val) = @_;
    return $self->_field_name('test', $val);
}

=item schedule_offset()

Gets/sets schedule-offset

=cut

sub schedule_offset{
    my ($self, $val) = @_;
    return $self->_field_class('schedule-offset', 'perfSONAR_PS::Client::PSConfig::ScheduleOffset', $val);
}

=item archive_refs()

Gets/sets archives as ArrayRef

=cut

sub archive_refs{
    my ($self, $val) = @_;
    return $self->_field_refs('archives', $val);
}

=item add_archive_ref()

Add archive

=cut

sub add_archive_ref{
    my ($self, $val) = @_;
    $self->_add_field_ref('archives', $val);
}

=item tools()

Gets/sets tools as ArrayRef

=cut

sub tools{
    my ($self, $val) = @_;
    return $self->_field('tools', $val);
}

=item add_tool()

Add tool

=cut

sub add_tool{
    my ($self, $val) = @_;
    $self->_add_list_item('tools', $val);
}

=item reference()

Gets/sets reference as HashRef

=cut

sub reference{
    my ($self, $val) = @_;
    return $self->_field_anyobj('reference', $val);
}

=item reference_param()

Gets/sets reference parameter

=cut

sub reference_param{
    my ($self, $field, $val) = @_;    
    return $self->_field_anyobj_param('reference', $field, $val);
}

=item disabled()

Gets/sets disabled

=cut

sub disabled{
    my ($self, $val) = @_;
    return $self->_field_bool('disabled', $val);
}



__PACKAGE__->meta->make_immutable;

1;
