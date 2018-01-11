package perfSONAR_PS::Client::PSConfig::Host;

use Mouse;

extends 'perfSONAR_PS::Client::PSConfig::BaseMetaNode';

=item archive_refs()

Gets/sets archives as an ArrayRef

=cut

sub archive_refs{
    my ($self, $val) = @_;
    return $self->_field_refs('archives', $val);
}

=item add_archive_ref()

Adds an archive

=cut

sub add_archive_ref{
    my ($self, $val) = @_;
    $self->_add_field_ref('archives', $val);
}

=item site()

Get/sets site

=cut

sub site{
    my ($self, $val) = @_;
    return $self->_field('site', $val);
}

=item tags()

Get/sets tags as an ArrayRef

=cut

sub tags{
    my ($self, $val) = @_;
    return $self->_field('tags', $val);
}

=item add_tag()

Adds a tag

=cut

sub add_tag{
    my ($self, $val) = @_;
    $self->_add_list_item('tags', $val);
}


=item disabled()

Get/sets disabled

=cut

sub disabled{
    my ($self, $val) = @_;
    return $self->_field_bool('disabled', $val);
}

=item no_agent()

Get/sets no-agent

=cut

sub no_agent{
    my ($self, $val) = @_;
    return $self->_field_bool('no-agent', $val);
}


__PACKAGE__->meta->make_immutable;

1;
