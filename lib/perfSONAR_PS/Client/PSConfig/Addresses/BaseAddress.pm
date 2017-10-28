package perfSONAR_PS::Client::PSConfig::Addresses::BaseAddress;

use Mouse;
use JSON;

extends 'perfSONAR_PS::Client::PSConfig::BaseMetaNode';

sub address{
    my ($self, $val) = @_;
    return $self->_field_host('address', $val);
}

sub agent_bind_address{
    my ($self, $val) = @_;
    return $self->_field_host('agent-bind-address', $val);
}

sub lead_bind_address{
    my ($self, $val) = @_;
    return $self->_field_host('lead-bind-address', $val);
}

sub pscheduler_address{
    my ($self, $val) = @_;
    return $self->_field_urlhostport('pscheduler-address', $val);
}

sub disabled{
    my ($self, $val) = @_;
    return $self->_field_bool('disabled', $val);
}

sub no_agent{
    my ($self, $val) = @_;
    return $self->_field_bool('no-agent', $val);
}

sub context_refs{
    my ($self, $val) = @_;
    return $self->_field_refs('contexts', $val);
}

sub add_context_ref{
    my ($self, $val) = @_;
    $self->_add_field_ref('contexts', $val);
}

__PACKAGE__->meta->make_immutable;

1;
