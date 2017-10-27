package perfSONAR_PS::Client::PSConfig::Host;

use Mouse;

extends 'perfSONAR_PS::Client::PSConfig::BaseMetaNode';

sub archive_refs{
    my ($self, $val) = @_;
    return $self->_field('archives', $val);
}

sub add_archive_ref{
    my ($self, $val) = @_;
    $self->_add_list_item('archives', $val);
}

sub site{
    my ($self, $val) = @_;
    return $self->_field('site', $val);
}

sub tags{
    my ($self, $val) = @_;
    return $self->_field('tags', $val);
}

sub add_tag{
    my ($self, $val) = @_;
    $self->_add_list_item('tags', $val);
}

sub disabled{
    my ($self, $val) = @_;
    return $self->_field_bool('disabled', $val);
}

sub no_agent{
    my ($self, $val) = @_;
    return $self->_field_bool('no-agent', $val);
}


__PACKAGE__->meta->make_immutable;

1;
