package perfSONAR_PS::Client::PSConfig::JQTransform;

use Mouse;
use JSON;

extends 'perfSONAR_PS::Client::PSConfig::BaseNode';

sub script{
    my ($self, $val) = @_;
    
    return $self->_field_list('script', $val);
}

sub output_raw{
    my ($self, $val) = @_;
    return $self->_field_bool('output-raw', $val);
}

sub args{
    my ($self, $val) = @_;
    return $self->_field_anyobj('args', $val);
}


__PACKAGE__->meta->make_immutable;

1;
