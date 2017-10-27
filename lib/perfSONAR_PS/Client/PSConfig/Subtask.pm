package perfSONAR_PS::Client::PSConfig::Subtask;

use Mouse;
use perfSONAR_PS::Client::PSConfig::ScheduleOffset;

extends 'perfSONAR_PS::Client::PSConfig::BaseMetaNode';

sub test_ref{
    my ($self, $val) = @_;
    return $self->_field('test', $val);
}

sub schedule_offset{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'schedule-offset'} = $val->data;
    }
    unless($self->data->{'schedule-offset'}){
        return;
    }
    return new perfSONAR_PS::Client::PSConfig::ScheduleOffset(data => $self->data->{'schedule-offset'});
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
