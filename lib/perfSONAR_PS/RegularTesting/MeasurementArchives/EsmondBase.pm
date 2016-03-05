package perfSONAR_PS::RegularTesting::MeasurementArchives::EsmondBase;

use strict;
use warnings;

our $VERSION = 3.4;

use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);

use Data::Dumper;
use Data::Validate::IP qw(is_ipv4);
use JSON qw(from_json to_json);
use LWP;
use perfSONAR_PS::Utils::DNS qw(discover_source_address);
use URI::Split qw(uri_split uri_join);

use Moose;

extends 'perfSONAR_PS::RegularTesting::MeasurementArchives::Base';

my $logger = get_logger(__PACKAGE__);

has 'username' => (is => 'rw', isa => 'Str|Undef');
has 'password' => (is => 'rw', isa => 'Str|Undef');
has 'database' => (is => 'rw', isa => 'Str');
has 'summary' => (is => 'rw', isa => 'ArrayRef[perfSONAR_PS::RegularTesting::MeasurementArchives::Config::EsmondSummary]', default => sub { [] });
has 'disable_default_summaries' => (is => 'rw', isa => 'Bool', default => sub { 0 });
has 'timeout' => (is => 'rw', isa => 'Int', default => sub { 60 });
has 'ca_certificate_file' => (is => 'rw', isa => 'Str|Undef');
has 'ca_certificate_path' => (is => 'rw', isa => 'Str|Undef');
has 'verify_hostname' => (is => 'rw', isa => 'Bool|Undef');

override 'supports_parallelism' => sub {
    return 1;
};

override 'store_results' => sub {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {  test => 1, 
                                         target  => 1,
                                         test_parameters => 1,
                                         results => 1,
                                      });
    my $test = $parameters->{test};
    my $target = $parameters->{target};
    my $test_parameters = $parameters->{test_parameters};
    my $results = $parameters->{results};
    
    #create/retrieve metadata
    my ($mdcode, $mdmsg, $metadata_uri) = $self->add_metadata(test => $test, target => $target, test_parameters => $test_parameters, results => $results);
    if($mdcode != 0){
        $logger->error("Error writing metadata ($mdcode) $mdmsg");
        return (1, "Error writing metadata: $mdmsg");
    }
    $logger->debug("Metadata URI: $metadata_uri");
    
    #create full url (also handles untainting)
    my ($scheme, $auth, $path, $query, $frag) = uri_split($self->database);
    my $md_url = uri_join($scheme, $auth, $metadata_uri);
    
    #write data
    my($dcode, $dmsg) = $self->add_data(write_url=> $md_url, test =>$test, target => $target, test_parameters => $test_parameters, results => $results);
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
    my $parameters = validate( @args, { test => 1, target => 1, test_parameters => 1, results => 1});
    my $test = $parameters->{test};
    my $target = $parameters->{target};
    my $test_parameters = $parameters->{test_parameters};
    my $results = $parameters->{results};
    my $metadata = {};
    
    if (!$results->{source} || !$results->{destination}){
        $logger->debug("TEST: ".Dumper($test));
        return (1, "Test returned unparsable results. Turn on DEBUG logging for more information.", "");
    }elsif(!$results->{source}->{address} || !$results->{destination}->{address}){
        my $err = "Error running test ";
        $err .= "from " . $results->{source}->{hostname} . " " if($results->{source}->{hostname});
        $err .= "to " . $results->{destination}->{hostname} . " " if($results->{destination}->{hostname});
        $err .= ($results->{raw_results} ? " with output " . $results->{raw_results} : " with unparsable output");
        $logger->debug("TEST: ".Dumper($test));
        return (1, $err, "");
    }
    
    $logger->debug("TEST: ".Dumper($test));
    
    #set common parameters
    $metadata->{'subject-type'} = 'point-to-point';
    $metadata->{'source'} = $results->{source}->{address};
    $metadata->{'destination'} = $results->{destination}->{address};
    $metadata->{'tool-name'} = $self->tool_name(test_parameters => $test_parameters, results => $results);
    $metadata->{'measurement-agent'} = $self->measurement_agent(test => $test, results => $results, target => $target); #TODO fix
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
    if($test->{schedule}->type() eq 'regular_intervals'){
        $metadata->{'time-interval'} = $test->{'schedule'}->interval;
    }elsif($test->{schedule}->type() eq 'streaming'){
        $metadata->{'time-interval'} = 0;
    }elsif($test->{schedule}->type() eq 'time_schedule'){
        $metadata->{'time-schedule'} = join(",", @{ $test->schedule->time_slots });
    }
    
    $metadata->{'event-types'} = [];
    
    #build map of sumamries
    my %summ_map = ();
    my @summaries = (@{$self->summary});
    unless($self->disable_default_summaries){
        push @summaries, $self->default_summaries;
    }
    my %summ_dup_tracker = ();
    foreach my $summ ( @summaries ){
        #prevent duplicate summaries
        my $summ_key = $summ->event_type . ':' . $summ->summary_type . ':' . $summ->summary_window;
        if($summ_dup_tracker{$summ_key}){
            next;
        }
        #create summary
        if(! exists $summ_map{$summ->event_type}){
            $summ_map{$summ->event_type} = [];
        }
        push @{$summ_map{$summ->event_type}}, {'summary-type' => $summ->summary_type , 'summary-window' => $summ->summary_window};
        $summ_dup_tracker{$summ_key} = 1;
    }
    
    #add event types
    foreach my $et (@{$self->event_types(test_parameters => $test_parameters, results => $results)}){
        my $et_obj = { 'event-type' => $et };
        if(exists $summ_map{$et} && $summ_map{$et}){
            $et_obj->{'summaries'} = $summ_map{$et};
        }
        push @{$metadata->{'event-types'}}, $et_obj;
    }
    #set application specific parameters
    $self->add_metadata_parameters(metadata=> $metadata, test=>$test, target => $target, test_parameters => $test_parameters, results => $results);
    
    #write to MA
    my $response = $self->send_http_request(url => $self->database, json => $metadata);
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
    my $parameters = validate( @args, {write_url => 1, test => 1, target => 1, test_parameters => 1, results => 1});
    my $write_url = $parameters->{write_url};
    my $results = $parameters->{results};
    my $test = $parameters->{test};
    my $target = $parameters->{target};
    my $test_parameters = $parameters->{test_parameters};
    
    #format data
    my $data = [];
    foreach my $ts (@{$self->get_timestamps(results => $results)}){
        my $vals = [];
        foreach my $et (@{$self->event_types(test_parameters => $test_parameters, results => $results)}){
            my $datum = $self->add_datum(timestamp=>$ts, event_type=> $et, results => $results);
            push @{$vals}, {'event-type' => $et, 'val' => $datum} if(defined $datum);
        }
        
        push @{$data}, { 'ts' => $ts, 'val' => $vals} if(scalar(@{$vals}) > 0);
    }
    
    $logger->debug("Results: ".Dumper($results));
    $logger->debug("esmond data: ".Dumper($data));
    
    #send to MA
    if(scalar(@{$data}) > 0){
        my $response = $self->send_http_request(url => $write_url, json => {'data' => $data}, put => 1);
        if($response->code() == 409){
            #if try to post duplicate datapoint, warn and move on
            $logger->warn("Error posting data to MA: " . $response->content);
        }elsif(!$response->is_success){
            my $errmsg = $self->build_err_msg(http_response => $response);
            return ($response->code, $errmsg);
        }
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

sub send_http_request {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {url => 1, json => 1, put => 0});
    my $url = $parameters->{url};
    my $json = $parameters->{json};
    my $client = LWP::UserAgent->new();
    $client->timeout($self->timeout);
    $client->env_proxy();
    $client->ssl_opts(verify_hostname => $self->verify_hostname) if defined ($self->verify_hostname);
    $client->ssl_opts(SSL_ca_file => $self->ca_certificate_file) if($self->ca_certificate_file);
    $client->ssl_opts(SSL_ca_path => $self->ca_certificate_path) if($self->ca_certificate_path);
    
    $logger->debug("Writing to esmond at " . $self->database);
    $logger->debug("Esmond request: " . to_json($json));
    my $response = {};
    if($parameters->{put} && $self->password){
        #API Key authentication
        my $req = HTTP::Request->new(PUT => "$url", HTTP::Headers->new(
            'Content-Type' => 'application/json',
            'Authorization' => "Token " . $self->password,
        ));
        $req->content(to_json($json));
        $response = $client->request($req);
    }elsif($self->password){
        #API Key authentication
        $response = $client->post($url, 
            'Content-Type' => 'application/json',
            'Authorization' => "Token " . $self->password,
            'Content' => to_json($json));
    }elsif($parameters->{put}){
        #IP authentication
        my $req = HTTP::Request->new(PUT => "$url", HTTP::Headers->new(
            'Content-Type' => 'application/json',
        ));
        $req->content(to_json($json));
        $response = $client->request($req);
    }else{
        #IP authentication
         $response = $client->post($url, 
            'Content-Type' => 'application/json',
            'Content' => to_json($json));
    }
    $logger->debug("Esmond response: " . $response->content);
    
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

sub create_summary_config(){
    my ($self, @args) = @_;
    my $parameters = validate( @args, {event_type => 1, summary_type => 1, summary_window=> 1  });
    
    return perfSONAR_PS::RegularTesting::MeasurementArchives::Config::EsmondSummary->new(
        event_type => $parameters->{event_type},
        summary_type => $parameters->{summary_type},
        summary_window => $parameters->{summary_window}
    );
}   

sub handle_failures(){
    my ($self, @args) = @_;
    my $parameters = validate( @args, {results => 1});
    my $results = $parameters->{results};
    
    if(!$results->errors || @{$results->errors} == 0){
        return undef;
    }
    
    my $err = join '--', @{$results->errors};
    return {'error' => $err};
}

sub tool_name {
     die("'tool_name' needs to be overridden");
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

sub default_summaries {
     return ();
}

sub measurement_agent {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { test => 1, target => 1, results => 1});
    my $test = $parameters->{test};
    my $target = $parameters->{target};
    my $results = $parameters->{results};
    #untaint addresses
    my $src_address = $1 if($results->{source}->{address} =~ /(.+)/);
    my $dst_address = $1 if($results->{destination}->{address} =~ /(.+)/);
    my $local_address = $1 if($test->local_address && $test->local_address =~ /(.+)/);
    my $target_address = $1 if($target->address =~ /(.+)/);
    
    # Check if this host is the destination first
    my $agent = discover_source_address(address => $src_address, local_address => $dst_address);

    # If this host isn't the destination, check if it's this source
    unless ($agent) {
        $agent = discover_source_address(address => $dst_address, local_address => $src_address);
    }
    
    # If using the results didn't work, try using the target address and the test's local address
    unless ($agent) {
        $agent = discover_source_address(address => $target_address, local_address => $local_address);
    }

    # Lastly, if none of that worked, lookup the local host's address to target address
    unless ($agent) {
        $agent = discover_source_address(address => $target_address);
    }

    return $agent;
}

package perfSONAR_PS::RegularTesting::MeasurementArchives::Config::EsmondSummary;

use Moose;
use Class::MOP::Class;

extends 'perfSONAR_PS::RegularTesting::Utils::SerializableObject';

has 'summary_type'     => (is => 'rw', isa => 'Str');
has 'event_type' => (is => 'rw', isa => 'Str');
has 'summary_window' => (is => 'rw', isa => 'Int');



1;
