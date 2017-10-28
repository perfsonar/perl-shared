package perfSONAR_PS::Client::PSConfig::Test;

use Mouse;

extends 'perfSONAR_PS::Client::PSConfig::BaseMetaNode';

sub type{
    my ($self, $val) = @_;
    return $self->_field('type', $val);
}

sub spec{
    my ($self, $val) = @_;
    return $self->_field_anyobj('spec', $val);
}

sub spec_param{
    my ($self, $field, $val) = @_;    
    return $self->_field_anyobj_param('spec', $field, $val);
}


__PACKAGE__->meta->make_immutable;

1;
