package perfSONAR_PS::Client::PSConfig::BaseMetaNode;

use Mouse;
use JSON qw(to_json from_json);
use Digest::MD5 qw(md5_base64);

extends 'perfSONAR_PS::Client::PSConfig::BaseNode';

has 'data' => (is => 'rw', isa => 'HashRef', default => sub { {} });

sub psconfig_meta{
    my ($self, $val) = @_;
    return $self->_field_anyobj('_meta', $val);
}

sub psconfig_meta_param{
    my ($self, $field, $val) = @_;    
    return $self->_field_anyobj_param('_meta', $field, $val);
}

sub remove_psconfig_meta {
    my ($self) = @_;
    $self->_remove_map('_meta');
}


__PACKAGE__->meta->make_immutable;

1;