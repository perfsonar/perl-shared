package perfSONAR_PS::Client::PSConfig::Context;

use Mouse;

extends 'perfSONAR_PS::Client::PSConfig::BaseMetaNode';

=item context()

Sets/gets context type

=cut

sub context{
    my ($self, $val) = @_;
    return $self->_field('context', $val);
}

=item context_data()

Sets/gets context data

=cut

sub context_data{
    my ($self, $val) = @_;
    return $self->_field_anyobj('data', $val);
}

=item context_data_param()

Sets/gets context parameter specified by field in data

=cut


sub context_data_param{
    my ($self, $field, $val) = @_;    
    return $self->_field_anyobj_param('data', $field, $val);
}


__PACKAGE__->meta->make_immutable;

1;
