package perfSONAR_PS::Client::Esmond::Metadata;

use Mouse;
use perfSONAR_PS::Client::Esmond::ApiFilters;
use perfSONAR_PS::Client::Esmond::EventType;
use perfSONAR_PS::Client::Esmond::EventTypeBulkPost;
use JSON qw(to_json from_json);

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
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'source'} = $val;
    }
    return $self->data->{'source'};
}

sub destination(){
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'destination'} = $val;
    }
    return $self->data->{'destination'};
}

sub input_source(){
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'input-source'} = $val;
    }
    return $self->data->{'input-source'};
}

sub input_destination(){
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'input-destination'} = $val;
    }
    return $self->data->{'input-destination'};
}

sub subject_type(){
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'subject-type'} = $val;
    }
    return $self->data->{'subject-type'};
}

sub tool_name(){
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'tool-name'} = $val;
    }
    return $self->data->{'tool-name'};
}

sub measurement_agent(){
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'measurement-agent'} = $val;
    }
    return $self->data->{'measurement-agent'};
}

sub get_field(){
    my ($self, $field) = @_;
    return $self->data->{$field};
}

sub set_field(){
    my ($self, $field, $val) = @_;
    $self->data->{$field} = $val;
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
            push @ets, new perfSONAR_PS::Client::Esmond::EventType(data => $et, url => $self->url, filters => $self->filters);
        }
    }
    return \@ets;
}

sub get_event_type(){
    my ($self, $type) = @_;
    if($self->data->{'event-types'} && ref($self->data->{'event-types'}) eq 'ARRAY'){
        foreach my $et(@{$self->data->{'event-types'}}){
            if($et->{'event-type'} eq $type){
                return new perfSONAR_PS::Client::Esmond::EventType(data => $et, url => $self->url, filters => $self->filters);
            }
        }
    }
    
    return undef;
}

sub metadata_count_total(){
    my ($self) = @_;
    
    #cannot set, only get
    return $self->data->{'metadata-count-total'};
}

sub generate_event_type_bulk_post(){
    my $self = shift;
    
    return new perfSONAR_PS::Client::Esmond::EventTypeBulkPost(
        'url' => $self->url,
        'metadata_uri' => $self->uri(),
        'filters' => $self->filters,
    );
}

sub add_event_type(){
    my ($self, $event_type_str) = @_;
    if(!$self->data->{'event-types'}){
        $self->data->{'event-types'} = [];
    }
    foreach my $et(@{$self->data->{'event-types'}}){
        if($et->{'event-type'} eq $event_type_str){
            return;
        }
    }
    push @{$self->data->{'event-types'}}, {'event-type' => $event_type_str, 'summaries' => []};
    
    
    return;
}

sub add_summary_type(){
    my ($self, $event_type_str, $summary_type_str, $summary_window_int) = @_;
    if(!$self->data->{'event-types'}){
        $self->data->{'event-types'} = [];
    }
    my $et_found = undef;
    foreach my $et(@{$self->data->{'event-types'}}){
        if($et->{'event-type'} eq $event_type_str){
            $et_found = $et;
            last;
        }
    }
    if(!$et_found){
        $et_found = {'event-type' => $event_type_str, 'summaries' => []};
        push @{$self->data->{'event-types'}}, $et_found;
    }
    foreach my $summ(@{$et_found->{'summaries'}}){
        if($summ->{'summary-type'} eq $summary_type_str && $summ->{'summary-window'} eq $summary_window_int){
            return;
        }
    }
    push @{$et_found->{'summaries'}}, {'summary-type' => $summary_type_str, 'summary-window' => $summary_window_int };
    
    
    return;
}

sub post_metadata() {
    my $self = shift;
    
    my $json_content = $self->_post(to_json($self->data));
    return -1 if($self->error);
    my $content = from_json($json_content);
    if(!$content){
        $self->_set_error("No metadata objects returned by post");
        return -1;
    }
    
    $self->data($content);
    
    return 0;
}

__PACKAGE__->meta->make_immutable;

1;