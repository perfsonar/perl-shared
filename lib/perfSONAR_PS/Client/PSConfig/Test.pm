package perfSONAR_PS::Client::PSConfig::Test;

use Mouse;

extends 'perfSONAR_PS::Client::PSConfig::BaseMetaNode';

sub type{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'type'} = $val;
    }
    return $self->data->{'type'};
}

sub spec{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'spec'} = $val;
    }
    return $self->data->{'spec'};
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
