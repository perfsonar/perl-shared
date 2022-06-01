package perfSONAR_PS::Client::Esmond::EventType;

use Mouse;
use perfSONAR_PS::Client::Esmond::ApiFilters;
use perfSONAR_PS::Client::Esmond::Summary;
use JSON qw(to_json);

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
            push @summaries, new perfSONAR_PS::Client::Esmond::Summary(data => $s, url => $self->url, filters => $self->filters);;
        }
    }
    return \@summaries;
}

sub get_summary {
    my ($self, $type, $window) = @_;
    if($self->data->{'summaries'} && ref($self->data->{'summaries'}) eq 'ARRAY'){
        foreach my $s(@{$self->data->{'summaries'}}){
            if($s->{'summary-type'} eq $type && $s->{'summary-window'} eq $window){
                return new perfSONAR_PS::Client::Esmond::Summary(data => $s, url => $self->url, filters => $self->filters);
            }
        }
    }
    
    return undef;
}

sub post_data {
    my ($self, $data_payload) = @_;
    
    my $json_payload = to_json({'ts' => $data_payload->ts, 'val' => $data_payload->val});
    my $content = $self->_post($json_payload);
    if($self->error){
        return -1;
    }
    
    return 0;
}

__PACKAGE__->meta->make_immutable;

1;