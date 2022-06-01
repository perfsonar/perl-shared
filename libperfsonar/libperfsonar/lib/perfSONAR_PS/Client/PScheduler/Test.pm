package perfSONAR_PS::Client::PScheduler::Test;

use Mouse;
use perfSONAR_PS::Client::PScheduler::Maintainer;

extends 'perfSONAR_PS::Client::PScheduler::BaseNode';

sub name{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'name'} = $val;
    }
    return $self->data->{'name'};
}

sub version{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'version'} = $val;
    }
    return $self->data->{'version'};
}

sub description{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'description'} = $val;
    }
    return $self->data->{'description'};
}

sub maintainer{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'maintainer'} = {};
        $self->data->{'maintainer'}->{"href"} = $val->href();
        $self->data->{'maintainer'}->{"name"} = $val->name();
        $self->data->{'maintainer'}->{"email"} = $val->email();
    }
    return undef unless($self->data->{'maintainer'});
    
    return new perfSONAR_PS::Client::PScheduler::Maintainer(
        href => $self->data->{'maintainer'}->{"href"},
        email => $self->data->{'maintainer'}->{"email"},
        name => $self->data->{'maintainer'}->{"name"},
    );
}

sub scheduling_class{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'scheduling-class'} = $val;
    }
    return $self->data->{'scheduling-class'};
}




__PACKAGE__->meta->make_immutable;

1;