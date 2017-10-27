package perfSONAR_PS::Client::PSConfig::ScheduleOffset;

use Mouse;
use JSON;

extends 'perfSONAR_PS::Client::PSConfig::BaseNode';

sub type{
    my ($self, $val) = @_;
    return $self->_field_enum('type', $val, {"start" => 1, "end" => 1});
}


sub relation{
    my ($self, $val) = @_;
    return $self->_field_enum('relation', $val, {"before" => 1, "after" => 1});
}

sub offset{
    my ($self, $val) = @_;
    return $self->_field_duration('offset', $val);
}


__PACKAGE__->meta->make_immutable;

1;
