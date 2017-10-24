package perfSONAR_PS::Client::PSConfig::BaseMetaNode;

use Mouse;
use JSON qw(to_json from_json);
use Digest::MD5 qw(md5_base64);

extends 'perfSONAR_PS::Client::PSConfig::BaseNode';

has 'data' => (is => 'rw', isa => 'HashRef', default => sub { {} });

sub psconfig_meta{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->data->{'_meta'} = $val;
    }
    
    return $self->data->{'_meta'};
}

sub psconfig_meta_param{
    my ($self, $field, $val) = @_;
    
    unless(defined $field){
        return undef;
    }
    
    if(defined $val){
        $self->_init_field($self->data, '_meta');
        $self->data->{'_meta'}->{$field} = $val;
    }
    
    unless($self->_has_field($self->data, "_meta")){
        return undef;
    }
    
    return $self->data->{'_meta'}->{$field};
}

sub remove_psconfig_meta_param {
    my ($self, $field) = @_;
    $self->_remove_map_item('_meta', $field);
}

sub remove_psconfig_meta {
    my ($self) = @_;
    $self->_remove_map('_meta');
}


__PACKAGE__->meta->make_immutable;

1;