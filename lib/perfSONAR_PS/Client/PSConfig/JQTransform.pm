package perfSONAR_PS::Client::PSConfig::JQTransform;

use Mouse;
use JSON;

extends 'perfSONAR_PS::Client::PSConfig::BaseNode';

sub script{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'script'} = $val;
    }
    return $self->data->{'script'};
}


sub output_raw{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'output_raw'} = $val ? JSON::true : JSON::false;
    }
    return $self->data->{'output_raw'} ? 1 : 0;
}


__PACKAGE__->meta->make_immutable;

1;
