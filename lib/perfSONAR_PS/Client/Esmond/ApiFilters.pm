package perfSONAR_PS::Client::Esmond::ApiFilters;

use Moose;

has 'metadata_filters' => (is => 'rw', isa => 'HashRef', default => sub { {} });
has 'time_filters' => (is => 'rw', isa => 'HashRef', default => sub { {} });
has 'auth_username' => (is => 'rw', isa => 'Str|Undef');
has 'auth_apikey' => (is => 'rw', isa => 'Str|Undef');
has 'timeout' => (is => 'rw', isa => 'Int', default => sub { 60 });
has 'ca_certificate_file' => (is => 'rw', isa => 'Str|Undef');
has 'ca_certificate_path' => (is => 'rw', isa => 'Str|Undef');
has 'verify_hostname' => (is => 'rw', isa => 'Bool|Undef');

sub source{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->metadata_filters->{'source'} = $val;
    }
    
    return $self->metadata_filters->{'source'};
}

sub destination{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->metadata_filters->{'destination'} = $val;
    }
    
    return $self->metadata_filters->{'destination'};
}

sub input_source{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->metadata_filters->{'input-source'} = $val;
    }
    
    return $self->metadata_filters->{'input-source'};
}

sub input_destination{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->metadata_filters->{'input-destination'} = $val;
    }
    
    return $self->metadata_filters->{'input-destination'};
}

sub measurement_agent{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->metadata_filters->{'measurement-agent'} = $val;
    }
    
    return $self->metadata_filters->{'measurement-agent'};
}


sub tool_name{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->metadata_filters->{'tool-name'} = $val;
    }
    
    return $self->metadata_filters->{'tool-name'};
}

sub event_type{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->metadata_filters->{'event-type'} = $val;
    }
    
    return $self->metadata_filters->{'event-type'};
}

sub summary_type{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->metadata_filters->{'summary-type'} = $val;
    }
    
    return $self->metadata_filters->{'summary-type'};
}

sub summary_window{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->metadata_filters->{'summary-window'} = $val;
    }
    
    return $self->metadata_filters->{'summary-window'};
}

sub time{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->time_filters->{'time'} = $val;
    }
    
    return $self->time_filters->{'time'};
}

sub time_start{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->time_filters->{'time-start'} = $val;
    }
    
    return $self->time_filters->{'time-start'};
}

sub time_end{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->time_filters->{'time-end'} = $val;
    }
    
    return $self->time_filters->{'time-end'};
}

sub time_range{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->time_filters->{'time-range'} = $val;
    }
    
    return $self->time_filters->{'time-range'};
}

sub headers {
    my $self = shift;
    my $headers = {};
    if($self->auth_username && $self->auth_apikey){
        $headers->{'Authorization'} = $self->auth_username . ":" . $self->auth_apikey;
    }
    
    return $headers;
}

1;