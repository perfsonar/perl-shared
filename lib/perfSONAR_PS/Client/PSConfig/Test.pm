package perfSONAR_PS::Client::PSConfig::Test;

use Mouse;

extends 'perfSONAR_PS::Client::PSConfig::BaseMetaNode';

sub type{
    my ($self, $val) = @_;
    return $self->_field('type', $val);
}

sub spec{
    my ($self, $val) = @_;
    return $self->_field('spec', $val);
}

sub spec_param {
    my ($self, $field, $val) = @_;
    
    unless(defined $field){
        return undef;
    }
    
    if(defined $val){
        $self->_init_field($self->data, 'spec');
        $self->data->{'spec'}->{$field} = $val;
    }
    
    return $self->data->{'spec'}->{$field};
}


__PACKAGE__->meta->make_immutable;

1;
