package perfSONAR_PS::Client::PSConfig::BaseMetaNode;

use Mouse;
use JSON qw(to_json from_json);
use Digest::MD5 qw(md5_base64);

extends 'perfSONAR_PS::Client::PSConfig::BaseNode';

has 'data' => (is => 'rw', isa => 'HashRef', default => sub { {} });

=item psconfig_meta()

Gets/sets _meta

=cut

sub psconfig_meta{
    my ($self, $val) = @_;
    return $self->_field_anyobj('_meta', $val);
}

=item psconfig_meta_param()

Gets/sets _meta parameter at given field

=cut

sub psconfig_meta_param{
    my ($self, $field, $val) = @_;    
    return $self->_field_anyobj_param('_meta', $field, $val);
}

=item remove_psconfig_meta()

Removes _meta parameter at given field

=cut

sub remove_psconfig_meta {
    my ($self) = @_;
    $self->_remove_map('_meta');
}


__PACKAGE__->meta->make_immutable;

1;