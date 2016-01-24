package perfSONAR_PS::Client::Esmond::EventTypeBulkPost;

use Mouse;
use perfSONAR_PS::Client::Esmond::ApiFilters;
use perfSONAR_PS::Client::Esmond::Summary;
use JSON qw(to_json);

extends 'perfSONAR_PS::Client::Esmond::BaseDataNode';

has 'metadata_uri' => (is => 'rw', isa => 'Str');

override '_uri' => sub {
    my $self = shift;
    return $self->metadata_uri;
};

sub add_data_point(){
    my ($self, $event_type, $ts, $val) = @_;
    
    unless(exists $self->data->{'data'}){
        $self->data->{'data'} = [];
    }
    
    my $ts_obj = undef;
    foreach my $d(@{$self->data->{'data'}}){
        if($d->{'ts'} == $ts){
            $ts_obj = $d;
            last;
        }
    }
    unless($ts_obj){
        $ts_obj = {'ts' => $ts, 'val' => []};
        push @{$self->data->{'data'}}, $ts_obj;
    }
    push @{$ts_obj->{'val'}}, {'event-type' => $event_type, 'val' => $val};
    
    return;
}

sub post_data {
    my ($self) = shift;
    
    my $json_payload = to_json($self->data);
    my $content = $self->_put($json_payload);
    if($self->error){
        return -1;
    }
    
    return 0;
}

__PACKAGE__->meta->make_immutable;

1;