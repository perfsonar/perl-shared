package perfSONAR_PS::Client::PSConfig::Context;

use Mouse;

extends 'perfSONAR_PS::Client::PSConfig::BaseMetaNode';

sub context{
    my ($self, $val) = @_;
    return $self->_field('context', $val);
}

sub context_data{
    my ($self, $val) = @_;
    return $self->_field_anyobj('data', $val);
}

sub context_data_param{
    my ($self, $field, $val) = @_;    
    return $self->_field_anyobj_param('data', $field, $val);
}


__PACKAGE__->meta->make_immutable;

1;
