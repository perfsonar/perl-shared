package perfSONAR_PS::Client::PSConfig::Task;

use Mouse;

extends 'perfSONAR_PS::Client::PSConfig::BaseMetaNode';

=item scheduled_by()

Gets/sets scheduled_by

=cut

sub scheduled_by{
    my ($self, $val) = @_;
    return $self->_field_intzero('scheduled-by', $val);
}

=item group_ref()

Gets/sets group_ref

=cut

sub group_ref{
    my ($self, $val) = @_;
    return $self->_field_name('group', $val);
}

=item test_ref()

Gets/sets test_ref

=cut


sub test_ref{
    my ($self, $val) = @_;
    return $self->_field_name('test', $val);
}

=item schedule_ref()

Gets/sets schedule_ref

=cut

sub schedule_ref{
    my ($self, $val) = @_;
    return $self->_field_name('schedule', $val);
}

=item archive_refs()

Gets/sets archive_refs as an ArrayRef

=cut

sub archive_refs{
    my ($self, $val) = @_;
    return $self->_field_refs('archives', $val);
}

=item add_archive_ref()

Adds archive to list

=cut

sub add_archive_ref{
    my ($self, $val) = @_;
    $self->_add_field_ref('archives', $val);
}

=item tools()

Gets/sets tools as an ArrayRef

=cut

sub tools{
    my ($self, $val) = @_;
    return $self->_field('tools', $val);
}

=item add_tool()

Adds tool to list

=cut

sub add_tool{
    my ($self, $val) = @_;
    $self->_add_list_item('tools', $val);
}

=item subtask_refs()

Gets/sets subtasks as an ArrayRef

=cut

sub subtask_refs{
    my ($self, $val) = @_;
    return $self->_field_refs('subtasks', $val);
}

=item add_subtask_ref()

Adds subtask to list

=cut

sub add_subtask_ref{
    my ($self, $val) = @_;
    $self->_add_field_ref('subtasks', $val);
}

=item priority()

Gets/sets priority

=cut

sub priority{
    my ($self, $val) = @_;
    return $self->_field_int('priority', $val);
}


=item reference()

Gets/sets reference as HashRef

=cut

sub reference{
    my ($self, $val) = @_;
    return $self->_field_anyobj('reference', $val);
}

=item reference_param()

Gets/sets reference parameter specified by field

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
