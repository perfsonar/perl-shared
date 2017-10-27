package perfSONAR_PS::Client::PSConfig::Schedule;

use Mouse;

extends 'perfSONAR_PS::Client::PSConfig::BaseMetaNode';

sub start{
    my ($self, $val) = @_;
    return $self->_field('start', $val);
}

sub slip{
    my ($self, $val) = @_;
    return $self->_field('slip', $val);
}

sub sliprand{
    my ($self, $val) = @_;
    return $self->_field_bool('sliprand', $val);
}

sub repeat{
    my ($self, $val) = @_;
    return $self->_field('repeat', $val);
}

sub until{
    my ($self, $val) = @_;
    return $self->_field('until', $val);
}

sub max_runs{
    my ($self, $val) = @_;
    return $self->_field('max-runs', $val);
}


__PACKAGE__->meta->make_immutable;

1;
