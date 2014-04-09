package perfSONAR_PS::Client::Esmond::Summary;

use Moose;
use  perfSONAR_PS::Client::Esmond::ApiFilters;

extends 'perfSONAR_PS::Client::Esmond::BaseDataNode';

override '_uri' => sub {
    my $self = shift;
    return $self->uri();
};

sub uri {
    my $self = shift;
    return $self->data->{'uri'};
}

sub summary_type {
    my $self = shift;
    return $self->data->{'summary-type'};
}

sub summary_window {
    my $self = shift;
    return $self->data->{'summary-window'};
}

1;