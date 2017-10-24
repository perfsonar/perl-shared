package perfSONAR_PS::Client::PSConfig::Archive;

use Mouse;
use perfSONAR_PS::Client::PSConfig::JQTransform;

extends 'perfSONAR_PS::Client::PSConfig::BaseMetaNode';

sub archiver{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'archiver'} = $val;
    }
    return $self->data->{'archiver'};
}

sub archiver_data{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'data'} = $val;
    }
    return $self->data->{'data'};
}

sub archiver_data_param {
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

sub transform{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'transform'} = $val->data;
    }
    return new perfSONAR_PS::Client::PSConfig::JQTransform(data => $self->data->{'transform'});
}

sub ttl{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'ttl'} = $val;
    }
    return $self->data->{'ttl'};
}



__PACKAGE__->meta->make_immutable;

1;
