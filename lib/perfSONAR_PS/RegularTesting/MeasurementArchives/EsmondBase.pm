package perfSONAR_PS::RegularTesting::MeasurementArchives::EsmondBase;

use strict;
use warnings;

our $VERSION = 3.4;

use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);

use Data::Dumper;
use JSON qw(from_json to_json);
use LWP;
use URI::Split qw(uri_split uri_join);

use Moose;

extends 'perfSONAR_PS::RegularTesting::MeasurementArchives::Base';

my $logger = get_logger(__PACKAGE__);

has 'username' => (is => 'rw', isa => 'Str');
has 'password' => (is => 'rw', isa => 'Str');
has 'database' => (is => 'rw', isa => 'Str');
has 'summary' => (is => 'rw', isa => 'ArrayRef[perfSONAR_PS::RegularTesting::MeasurementArchives::Config::EsmondSummary]', default => sub { [] });

override 'store_results' => sub {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {
                                         results => 1,
                                      });
    my $results = $parameters->{results};
    
    #create/retrieve metadata
    my ($mdcode, $mdmsg, $metadata_uri) = $self->add_metadata(results => $results);
    if($mdcode != 0){
        $logger->error("Error writing metadata ($mdcode) $mdmsg");
        return (1, "Error writing metadata: $mdmsg");
    }
    $logger->info("Metadata URI: $metadata_uri");
    
    #create full url (also handles untainting)
    my ($scheme, $auth, $path, $query, $frag) = uri_split($self->database);
    my $md_url = uri_join($scheme, $auth, $metadata_uri);
    
    #write data
    my($dcode, $dmsg) = $self->add_data(write_url=> $md_url, results => $results);
    if($dcode != 0){
        $logger->error("Error writing data ($dcode) $dmsg");
        return (1, "Error writing data: $dmsg");
    }
    
    return (0, "");
};

override 'nonce' => sub {
    my ($self) = @_;
    
    my ($scheme, $auth, $path, $query, $frag) = uri_split($self->database);
    my $type = $self->type();
    $type =~ s/\//_/g;
    
    return "${type}_${auth}";
};

sub add_metadata {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {results => 1});
    my $results = $parameters->{results};
    my $metadata = {};
    if (!$results->{source}){
        return (1, "No source provided", "");
    }
    if (!$results->{destination}){
        return (1, "No destination provided", "");
    }
    if (!$results->{source}->{address}){
        return (1, "No source address provided", "");
    }
    if (!$results->{destination}->{address}){
        return (1, "No destination address provided", "");
    }
    
    #set common parameters
    $metadata->{'subject-type'} = 'point-to-point';
    $metadata->{'source'} = $results->{source}->{address};
    $metadata->{'destination'} = $results->{destination}->{address};
    $metadata->{'tool-name'} = 'bwctl/ping';
    $metadata->{'measurement-agent'} = $results->{source}->{address}; #TODO fix
    if($results->{source}->{hostname}){
        $metadata->{'input-source'} = $results->{source}->{hostname};
    }else{
        $metadata->{'input-source'} = $results->{source}->{address};
    }
    if($results->{destination}->{hostname}){
        $metadata->{'input-destination'} = $results->{destination}->{hostname};
    }else{
        $metadata->{'input-destination'} = $results->{destination}->{address};
    }
    #todo set time-interval
    $metadata->{'event-types'} = [];
    
    #build map of sumamries
    my %summ_map = ();
    foreach my $summ (@{$self->summary}){
        if(! exists $summ_map{$summ->event_type}){
            $summ_map{$summ->event_type} = [];
        }
        push @{$summ_map{$summ->event_type}}, {'summary-type' => $summ->summary_type , 'summary-window' => $summ->summary_window};
    }
    
    #add event types
    foreach my $et (@{$self->event_types()}){
        my $et_obj = { 'event-type' => $et };
        if(exists $summ_map{$et} && $summ_map{$et}){
            $et_obj->{'summaries'} = $summ_map{$et};
        }
        push @{$metadata->{'event-types'}}, $et_obj;
    }
    #set application specific parameters
    $self->add_metadata_parameters(metadata=> $metadata, results => $results);
    
    #write to MA
    my $response = $self->send_post(url => $self->database, json => $metadata);
    if(!$response->is_success){
        my $errmsg = $self->build_err_msg(http_response => $response);
        return ($response->code , $errmsg,"");
    }
    my $response_metadata = from_json($response->content);
    if(! $response_metadata){
        return (1 ,"No metadata object returned.","");
    }
    if(! $response_metadata->{'uri'}){
        return (1 ,"No metadata URI returned.","");
    }
    
    return (0, "", $response_metadata->{'uri'});
}

sub add_data {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {write_url => 1, results => 1});
    my $write_url = $parameters->{write_url};
    my $results = $parameters->{results};
    
    #format data
    my $data = [];
    foreach my $ts (@{$self->get_timestamps(results => $results)}){
        my $vals = [];
        foreach my $et (@{$self->event_types()}){
            my $datum = $self->add_datum(timestamp=>$ts, event_type=> $et, results => $results);
            push @{$vals}, {'event-type' => $et, 'val' => $datum} if(defined $datum);
        }
        push @{$data}, { 'ts' => $ts, 'val' => $vals};
    }
    
    $logger->debug("DATA: ".Dumper($data));
    
    #send to MA
    my $response = $self->send_post(url => $write_url, json => {'data' => $data});
    if(!$response->is_success){
        my $errmsg = $self->build_err_msg(http_response => $response);
        return ($response->code, $errmsg);
    }
    
    return (0, "")
}

sub build_err_msg {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {http_response => 1});
    my $response = $parameters->{http_response};
    
    my $errmsg = $response->status_line;
    if($response->content){
        #try to parse json
        eval{
            my $response_json = from_json($response->content);
            if (exists $response_json->{'error'} && $response_json->{'error'}){
                $errmsg .= ': ' . $response_json->{'error'};
            }
        };
    }
    
    return $errmsg;
}

sub send_post {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {url => 1, json => 1});
    my $url = $parameters->{url};
    my $json = $parameters->{json};
    my $auth_string = $self->username . ":" . $self->password;
    my $client = LWP::UserAgent->new();
    
    $logger->debug("Writing to esmond at " . $self->database);
    $logger->debug("Esmond request: " . to_json($json));
    my $response = $client->post($url, 
        'Content-Type' => 'application/json',
        'Authorization' => "ApiKey $auth_string",
        'Content' => to_json($json));
    $logger->debug("Esmond repsonse: " . $response->content);
    
    return $response;
}

sub add_metadata_opt_parameter{
    my ($self, @args) = @_;
    my $parameters = validate( @args, {metadata => 1, key => 1, value => 1});
    my $metadata = $parameters->{metadata};
    my $key = $parameters->{key};
    my $value = $parameters->{value};
    if($value){
        $metadata->{$key} = $value;
    }
}

sub get_timestamps {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {results => 1});
    my $results = $parameters->{results};
    
    return [$results->{'start_time'}->epoch()];
}

sub event_types {
    die("'event_types' needs to be overridden");
}

sub add_metadata_parameters{
    die("'add_metadata_parameters' needs to be overridden");
}

sub add_datum {
     die("'add_datum' needs to be overridden");
}


package perfSONAR_PS::RegularTesting::MeasurementArchives::Config::EsmondSummary;

use Moose;
use Class::MOP::Class;

extends 'perfSONAR_PS::RegularTesting::Utils::SerializableObject';

has 'summary_type'     => (is => 'rw', isa => 'Str');
has 'event_type' => (is => 'rw', isa => 'Str');
has 'summary_window' => (is => 'rw', isa => 'Int');



1;
