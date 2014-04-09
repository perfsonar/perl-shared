package perfSONAR_PS::Client::Esmond::Metadata;

use Moose;
use perfSONAR_PS::Client::Esmond::ApiFilters;
use perfSONAR_PS::Client::Esmond::EventType;

extends 'perfSONAR_PS::Client::Esmond::BaseNode';

sub uri(){
    my $self = shift;
    return $self->data->{'uri'};
}

sub metadata_key(){
    my $self = shift;
    return $self->data->{'metadata-key'};
}

sub source(){
    my $self = shift;
    return $self->data->{'source'};
}

sub destination(){
    my $self = shift;
    return $self->data->{'destination'};
}

sub input_source(){
    my $self = shift;
    return $self->data->{'input-source'};
}

sub input_destination(){
    my $self = shift;
    return $self->data->{'input-destination'};
}

sub subject_type(){
    my $self = shift;
    return $self->data->{'subject-type'};
}

sub tool_name(){
    my $self = shift;
    return $self->data->{'tool-name'};
}

sub measurement_agent(){
    my $self = shift;
    return $self->data->{'measurement-agent'};
}

sub get_field(){
    my ($self, $field) = @_;
    return $self->data->{$field};
}

sub event_types(){
    my $self = shift;
    my @ets = ();
    if($self->data->{'event-types'} && ref($self->data->{'event-types'}) eq 'ARRAY'){
        foreach my $et(@{$self->data->{'event-types'}}){
            push @ets, $et->{'event-type'};
        }
    }
    return \@ets;
}

sub get_all_event_types(){
    my $self = shift;
    my @ets = ();
    if($self->data->{'event-types'} && ref($self->data->{'event-types'}) eq 'ARRAY'){
        foreach my $et(@{$self->data->{'event-types'}}){
            push @ets, new perfSONAR_PS::Client::Esmond::EventType(data => $et, api_url => $self->api_url, filters => $self->filters);
        }
    }
    return \@ets;
}

sub get_event_type(){
    my ($self, $type) = @_;
    if($self->data->{'event-types'} && ref($self->data->{'event-types'}) eq 'ARRAY'){
        foreach my $et(@{$self->data->{'event-types'}}){
            if($et->{'event-type'} eq $type){
                return new perfSONAR_PS::Client::Esmond::EventType(data => $et, api_url => $self->api_url, filters => $self->filters);
            }
        }
    }
    
    return undef;
}

1;