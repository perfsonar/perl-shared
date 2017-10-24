package perfSONAR_PS::Client::PSConfig::Context;

use Mouse;

extends 'perfSONAR_PS::Client::PSConfig::BaseMetaNode';

sub context{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'context'} = $val;
    }
    return $self->data->{'context'};
}

sub context_data{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'data'} = $val;
    }
    return $self->data->{'data'};
}

sub context_data_param {
    my ($self, $field, $val) = @_;
    
    unless(defined $field){
        return undef;
    }
    
    if(defined $val){
        $self->_init_field($self->data, 'data');
        $self->data->{'data'}->{$field} = $val;
    }
    
    return $self->data->{'data'}->{$field};
}



__PACKAGE__->meta->make_immutable;

1;
