package perfSONAR_PS::Client::Esmond::EventType;

use Moose;
use perfSONAR_PS::Client::Esmond::ApiFilters;
use perfSONAR_PS::Client::Esmond::Summary;

extends 'perfSONAR_PS::Client::Esmond::BaseDataNode';

override '_uri' => sub {
    my $self = shift;
    return $self->base_uri();
};

sub base_uri {
    my $self = shift;
    return $self->data->{'base-uri'};
}

sub event_type {
    my $self = shift;
    return $self->data->{'event-type'};
}

sub summaries {
    my $self = shift;
    my @summaries = ();
    if($self->data->{'summaries'} && ref($self->data->{'summaries'}) eq 'ARRAY'){
        foreach my $s(@{$self->data->{'summaries'}}){
            push @summaries, [$s->{'summary-type'}, $s->{'summary-window'}];
        }
    }
    return \@summaries;
}

sub get_all_summaries {
    my $self = shift;
    my @summaries = ();
    if($self->data->{'summaries'} && ref($self->data->{'summaries'}) eq 'ARRAY'){
        foreach my $s(@{$self->data->{'summaries'}}){
            push @summaries, new perfSONAR_PS::Client::Esmond::Summary(data => $s, api_url => $self->api_url, filters => $self->filters);;
        }
    }
    return \@summaries;
}

sub get_summary {
    my ($self, $type, $window) = @_;
    if($self->data->{'summaries'} && ref($self->data->{'summaries'}) eq 'ARRAY'){
        foreach my $s(@{$self->data->{'summaries'}}){
            if($s->{'summary-type'} eq $type && $s->{'summary-window'} eq $window){
                return new perfSONAR_PS::Client::Esmond::Summary(data => $s, api_url => $self->api_url, filters => $self->filters);
            }
        }
    }
    
    return undef;
}

1;