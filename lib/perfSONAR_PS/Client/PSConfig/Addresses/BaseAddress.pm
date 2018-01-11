package perfSONAR_PS::Client::PSConfig::Addresses::BaseAddress;

use Mouse;
use JSON;

extends 'perfSONAR_PS::Client::PSConfig::BaseMetaNode';

#properties inherited from a parent that don't mess with the json. used internally in 
# test iteration and should not generally be used directly by clients
has '_parent_disabled' => (is => 'ro', isa => 'Bool|Undef', writer => '_set_parent_disabled');
has '_parent_no_agent' => (is => 'ro', isa => 'Bool|Undef', writer => '_set_parent_no_agent');
has '_parent_host_ref' => (is => 'ro', isa => 'Str|Undef', writer => '_set_parent_host_ref');
has '_parent_address' => (is => 'ro', isa => 'Str|Undef', writer => '_set_parent_address');

=item address()

Gets/sets address

=cut

sub address{
    my ($self, $val) = @_;
    return $self->_field_host('address', $val);
}

=item lead_bind_address()

Gets/sets lead-bind-address

=cut

sub lead_bind_address{
    my ($self, $val) = @_;
    return $self->_field_host('lead-bind-address', $val);
}

=item pscheduler_address()

Gets/sets pscheduler-address

=cut

sub pscheduler_address{
    my ($self, $val) = @_;
    return $self->_field_urlhostport('pscheduler-address', $val);
}

=item disabled()

Gets/sets disabled

=cut

sub disabled{
    my ($self, $val) = @_;
    return $self->_field_bool('disabled', $val);
}

=item no_agent()

Gets/sets no-agent

=cut

sub no_agent{
    my ($self, $val) = @_;
    return $self->_field_bool('no-agent', $val);
}

=item context_refs()

Gets/sets contexts as an ArrayRef

=cut

sub context_refs{
    my ($self, $val) = @_;
    return $self->_field_refs('contexts', $val);
}

=item add_context_ref()

Adds a context to the array. 

=cut

sub add_context_ref{
    my ($self, $val) = @_;
    $self->_add_field_ref('contexts', $val);
}

sub _is_no_agent{
    my ($self) = @_;
    return $self->no_agent() || $self->_parent_no_agent();
}

sub _is_disabled{
    my ($self) = @_;
    return $self->disabled() || $self->_parent_disabled();
}


__PACKAGE__->meta->make_immutable;

1;
