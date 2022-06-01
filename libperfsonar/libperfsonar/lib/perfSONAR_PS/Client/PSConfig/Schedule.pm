package perfSONAR_PS::Client::PSConfig::Schedule;

use Mouse;

extends 'perfSONAR_PS::Client::PSConfig::BaseMetaNode';

=item start()

Gets/sets start

=cut

sub start{
    my ($self, $val) = @_;
    return $self->_field_timestampabsrel('start', $val);
}

=item slip()

Gets/sets slip

=cut

sub slip{
    my ($self, $val) = @_;
    return $self->_field_duration('slip', $val);
}

=item sliprand()

Gets/sets sliprand

=cut

sub sliprand{
    my ($self, $val) = @_;
    return $self->_field_bool('sliprand', $val);
}

=item repeat()

Gets/sets repeat

=cut

sub repeat{
    my ($self, $val) = @_;
    return $self->_field_duration('repeat', $val);
}

=item until()

Gets/sets until

=cut

sub until{
    my ($self, $val) = @_;
    return $self->_field_timestampabsrel('until', $val);
}

=item max_runs()

Gets/sets max_runs

=cut

sub max_runs{
    my ($self, $val) = @_;
    return $self->_field_cardinal('max-runs', $val);
}


__PACKAGE__->meta->make_immutable;

1;
