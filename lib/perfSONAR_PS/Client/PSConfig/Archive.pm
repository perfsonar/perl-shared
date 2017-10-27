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
    return $self->_field('data', $val);
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
    return $self->_field_duration('ttl', $val);
}



__PACKAGE__->meta->make_immutable;

1;
