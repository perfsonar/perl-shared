package perfSONAR_PS::Client::Esmond::Summary;

use Mouse;
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

sub time_updated {
    my $self = shift;
    return $self->data->{'time-updated'};
}

sub datetime_updated {
    my $self = shift;
    my $ts = $self->time_updated();
    if($ts){
        return DateTime->from_epoch(epoch => $self->time_updated());
    }
    return undef;
}

__PACKAGE__->meta->make_immutable;

1;