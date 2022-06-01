package perfSONAR_PS::Client::PSConfig::Test;

use Mouse;

extends 'perfSONAR_PS::Client::PSConfig::BaseMetaNode';

=item type()

Gets/sets test type

=cut

sub type{
    my ($self, $val) = @_;
    return $self->_field('type', $val);
}

=item spec()

Gets/sets test spec as HashRef

=cut

sub spec{
    my ($self, $val) = @_;
    return $self->_field_anyobj('spec', $val);
}

=item spec_param()

Gets/sets test spec parameter specified by field

=cut

sub spec_param{
    my ($self, $field, $val) = @_;    
    return $self->_field_anyobj_param('spec', $field, $val);
}


__PACKAGE__->meta->make_immutable;

1;
