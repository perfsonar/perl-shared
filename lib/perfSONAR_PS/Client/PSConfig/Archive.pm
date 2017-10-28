package perfSONAR_PS::Client::PSConfig::Archive;

use Mouse;
use perfSONAR_PS::Client::PSConfig::JQTransform;

extends 'perfSONAR_PS::Client::PSConfig::BaseMetaNode';

sub archiver{
    my ($self, $val) = @_;
    return $self->_field('archiver', $val);
}

sub archiver_data{
    my ($self, $val) = @_;
    return $self->_field_anyobj('data', $val);
}

sub archiver_data_param {
    my ($self, $field, $val) = @_;
    return $self->_field_anyobj_param('data', $field, $val);
}

sub transform{
    my ($self, $val) = @_;
    return $self->_field_class('transform', 'perfSONAR_PS::Client::PSConfig::JQTransform', $val);
}

sub ttl{
    my ($self, $val) = @_;
    return $self->_field_duration('ttl', $val);
}



__PACKAGE__->meta->make_immutable;

1;
