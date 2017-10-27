package perfSONAR_PS::Client::PSConfig::ScheduleOffset;

use Mouse;
use JSON;

extends 'perfSONAR_PS::Client::PSConfig::BaseNode';

sub type{
    my ($self, $val) = @_;
    return $self->_field('type', $val);
}


sub relation{
    my ($self, $val) = @_;
    return $self->_field('relation', $val);
}

sub offset{
    my ($self, $val) = @_;
    return $self->_field('offset', $val);
}


__PACKAGE__->meta->make_immutable;

1;
