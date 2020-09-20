package perfSONAR_PS::Client::PScheduler::ApiConnect;

=head1 NAME

perfSONAR_PS::Client::PScheduler::ApiConnect - A client for interacting with pScheduler

=head1 DESCRIPTION

A client for interacting with pScheduler

=cut

use Mouse;
use Params::Validate qw(:all);
use perfSONAR_PS::Client::Utils qw(send_http_request build_err_msg extract_url_uuid);
use JSON qw(from_json to_json encode_json decode_json);
use URI::Encode;

use perfSONAR_PS::Client::PScheduler::ApiFilters;
use perfSONAR_PS::Client::PScheduler::Task;
use perfSONAR_PS::Client::PScheduler::Test;
use perfSONAR_PS::Client::PScheduler::Tool;

our $VERSION = 4.0;

has 'url' => (is => 'rw', isa => 'Str');
has 'bind_address' => (is => 'rw', isa => 'Str|Undef');
has 'bind_map' => (is => 'rw', isa => 'HashRef', default => sub { {} });
has 'lead_address_map' => (is => 'rw', isa => 'HashRef', default => sub { {} });
has 'filters' => (is => 'rw', isa => 'perfSONAR_PS::Client::PScheduler::ApiFilters', default => sub { new perfSONAR_PS::Client::PScheduler::ApiFilters(); });
has 'error' => (is => 'ro', isa => 'Str', writer => '_set_error');

sub get_tasks() {
    my $self = shift;

    #build url
    my $tasks_url = $self->url;
    chomp($tasks_url);
    $tasks_url .= "/" if($self->url !~ /\/$/);
    $tasks_url .= "tasks";
    
    my %filters = ("detail" => 1, "expanded" => 1);
    if($self->filters->task_filters){
        $filters{"json"} = to_json($self->filters->task_filters);
    }
    my $response = send_http_request(
        connection_type => 'GET', 
        url => $tasks_url, 
        timeout => $self->filters->timeout,
        get_params => \%filters,
        ca_certificate_file => $self->filters->ca_certificate_file,
        ca_certificate_path => $self->filters->ca_certificate_path,
        verify_hostname => $self->filters->verify_hostname,
        local_address => $self->bind_address,
        bind_map => $self->bind_map,
        address_map => $self->lead_address_map,
        #headers => $self->filters->headers()
    );

    if(!$response->is_success){
        my $msg = build_err_msg(http_response => $response);
        $self->_set_error($msg);
        return;
    }

    my $response_json = from_json($response->body);
    if(! $response_json){
        $self->_set_error("No task objects returned.");
        return;
    }

    if(ref($response_json) ne 'ARRAY'){
        $self->_set_error("Tasks must be an array not " . ref($response_json));
        return;
    }

    my @tasks = ();
    foreach my $task_response_json(@{$response_json}){
        my $task_url;
        my $task;
        my $has_detail = 0;
        if($task_response_json->{"detail"} && $task_response_json->{"detail"}->{"href"}){
            #check if we get detail back since was not added until 4.0.1
            $task_url = $task_response_json->{"detail"}->{"href"};
            $has_detail = 1;
        }elsif($task_response_json->{"href"}){
            #if no detail, we have some backward compatibility to do
            $task_url = $task_response_json->{"href"};
        }else{
            next;
        }
        my $task_uuid = extract_url_uuid(url => $task_url);
        unless($task_uuid){
            $self->_set_error("Unable to extract UUID from url $task_url");
            next;
        }
        
        if($has_detail){
            #we got the detail, so create the object
            $task = new perfSONAR_PS::Client::PScheduler::Task(
                data => $task_response_json, 
                url => $self->url, 
                filters => $self->filters, 
                uuid => $task_uuid, 
                bind_map => $self->bind_map, 
                lead_address_map => $self->lead_address_map
            );
        }else{
            #no detail, so we have to retrieve it
            $task = $self->get_task($task_uuid);
        }
        
        unless($task){
            #there was an error
            next;
        }
        push @tasks, $task;
    }
    
    return \@tasks;
}

sub get_task() {
    my ($self, $task_uuid) = @_;
    
    #build url
    my $task_url = $self->url;
    chomp($task_url);
    $task_url .= "/" if($self->url !~ /\/$/);
    $task_url .= "tasks/$task_uuid";
    
    #fetch task
    my $task_response = send_http_request(
        connection_type => 'GET', 
        url => $task_url, 
        get_params => { 'detail' => 1 },
        timeout => $self->filters->timeout,
        ca_certificate_file => $self->filters->ca_certificate_file,
        ca_certificate_path => $self->filters->ca_certificate_path,
        verify_hostname => $self->filters->verify_hostname,
        local_address => $self->bind_address,
        bind_map => $self->bind_map,
        address_map => $self->lead_address_map,
    );
    if(!$task_response->is_success){
        my $msg = build_err_msg(http_response => $task_response);
        $self->_set_error($msg);
        return;
    }
    my $task_response_json = from_json($task_response->body);
    if(!$task_response_json){
        $self->_set_error("No task object returned from $task_url");
        return;
    }
    
    return new perfSONAR_PS::Client::PScheduler::Task(
            data => $task_response_json, 
            url => $self->url, 
            filters => $self->filters, 
            uuid => $task_uuid, 
            bind_map => $self->bind_map, 
            lead_address_map => $self->lead_address_map
        );
}

sub get_tools() {
    my $self = shift;
    
    #build url
    my $tools_url = $self->url;
    chomp($tools_url);
    $tools_url .= "/" if($self->url !~ /\/$/);
    $tools_url .= "tools";
    
    my %filters = ();

    my $response = send_http_request(
        connection_type => 'GET', 
        url => $tools_url, 
        timeout => $self->filters->timeout,
        ca_certificate_file => $self->filters->ca_certificate_file,
        ca_certificate_path => $self->filters->ca_certificate_path,
        verify_hostname => $self->filters->verify_hostname,
        local_address => $self->bind_address,
        bind_map => $self->bind_map,
        address_map => $self->lead_address_map,
        #headers => $self->filters->headers()
    );
     
    if(!$response->is_success){
        my $msg = build_err_msg(http_response => $response);
        $self->_set_error($msg);
        return;
    }
    my $response_json = from_json($response->body);
    if(! $response_json){
        $self->_set_error("No tool objects returned.");
        return;
    }
    if(ref($response_json) ne 'ARRAY'){
        $self->_set_error("Tools must be an array not " . ref($response_json));
        return;
    }
    
    my @tools = ();
    foreach my $tool_url(@{$response_json}){
        my $tool_name = extract_url_uuid(url => $tool_url);
        unless($tool_name){
            $self->_set_error("Unable to extract name from url $tool_url");
            return;
        }
        my $tool = $self->get_tool($tool_name);
        unless($tool){
            #there was an error
            return;
        }
        push @tools, $tool;
    }
    
    return \@tools;
}

sub get_tool() {
    my ($self, $tool_name) = @_;
    
    #build url
    my $tool_url = $self->url;
    chomp($tool_url);
    $tool_url .= "/" if($self->url !~ /\/$/);
    $tool_url .= "tools/$tool_name";
    
    #fetch tool
    my $tool_response = send_http_request(
        connection_type => 'GET', 
        url => $tool_url, 
        timeout => $self->filters->timeout,
        ca_certificate_file => $self->filters->ca_certificate_file,
        ca_certificate_path => $self->filters->ca_certificate_path,
        verify_hostname => $self->filters->verify_hostname,
        local_address => $self->bind_address,
        bind_map => $self->bind_map,
        address_map => $self->lead_address_map,
    );
    if(!$tool_response->is_success){
        my $msg = build_err_msg(http_response => $tool_response);
        $self->_set_error($msg);
        return;
    }
    my $tool_response_json = from_json($tool_response->body);
    if(!$tool_response_json){
        $self->_set_error("No tool object returned from $tool_url");
        return;
    }
    
    return new perfSONAR_PS::Client::PScheduler::Tool(data => $tool_response_json, url => $tool_url, filters => $self->filters, uuid => $tool_name);
}

sub get_test_urls() {
    my $self = shift;
    
    #build url
    my $tests_url = $self->url;
    chomp($tests_url);
    $tests_url .= "/" if($self->url !~ /\/$/);
    $tests_url .= "tests";
    
    my %filters = ();

    my $response = send_http_request(
        connection_type => 'GET', 
        url => $tests_url, 
        timeout => $self->filters->timeout,
        ca_certificate_file => $self->filters->ca_certificate_file,
        ca_certificate_path => $self->filters->ca_certificate_path,
        verify_hostname => $self->filters->verify_hostname,
        local_address => $self->bind_address,
        bind_map => $self->bind_map,
        address_map => $self->lead_address_map,
        #headers => $self->filters->headers()
    );
     
    if(!$response->is_success){
        my $msg = build_err_msg(http_response => $response);
        $self->_set_error($msg);
        return;
    }
    my $response_json = from_json($response->body);
    if(! $response_json){
        $self->_set_error("No test objects returned.");
        return;
    }
    if(ref($response_json) ne 'ARRAY'){
        $self->_set_error("Tests must be an array not " . ref($response_json));
        return;
    }
    
    return $response_json;
}

sub get_tests() {
    my $self = shift;
    
    #build url
    my $tests_url = $self->url;
    chomp($tests_url);
    $tests_url .= "/" if($self->url !~ /\/$/);
    $tests_url .= "tests";
    
    my %filters = ();

    my $response = send_http_request(
        connection_type => 'GET', 
        url => $tests_url, 
        timeout => $self->filters->timeout,
        ca_certificate_file => $self->filters->ca_certificate_file,
        ca_certificate_path => $self->filters->ca_certificate_path,
        verify_hostname => $self->filters->verify_hostname,
        local_address => $self->bind_address,
        bind_map => $self->bind_map,
        address_map => $self->lead_address_map,
        #headers => $self->filters->headers()
    );
     
    if(!$response->is_success){
        my $msg = build_err_msg(http_response => $response);
        $self->_set_error($msg);
        return;
    }
    my $response_json = from_json($response->body);
    if(! $response_json){
        $self->_set_error("No test objects returned.");
        return;
    }
    if(ref($response_json) ne 'ARRAY'){
        $self->_set_error("Tests must be an array not " . ref($response_json));
        return;
    }
    
    my @tests = ();
    foreach my $test_url(@{$response_json}){
        my $test_name = extract_url_uuid(url => $test_url);
        unless($test_name){
            $self->_set_error("Unable to extract name from url $test_url");
            return;
        }
        my $test = $self->get_test($test_name);
        unless($test){
            #there was an error
            return;
        }
        push @tests, $test;
    }
    
    return \@tests;
}

sub get_test() {
    my ($self, $test_name) = @_;
    
    #build url
    my $test_url = $self->url;
    chomp($test_url);
    $test_url .= "/" if($self->url !~ /\/$/);
    $test_url .= "tests/$test_name";
    
    #fetch test
    my $test_response = send_http_request(
        connection_type => 'GET', 
        url => $test_url, 
        timeout => $self->filters->timeout,
        ca_certificate_file => $self->filters->ca_certificate_file,
        ca_certificate_path => $self->filters->ca_certificate_path,
        verify_hostname => $self->filters->verify_hostname,
        local_address => $self->bind_address,
        bind_map => $self->bind_map,
        address_map => $self->lead_address_map,
    );
    if(!$test_response->is_success){
        my $msg = build_err_msg(http_response => $test_response);
        $self->_set_error($msg);
        return;
    }
    my $test_response_json = from_json($test_response->body);
    if(!$test_response_json){
        $self->_set_error("No test object returned from $test_url");
        return;
    }
    
    return new perfSONAR_PS::Client::PScheduler::Test(data => $test_response_json, url => $test_url, filters => $self->filters, uuid => $test_name);
}

sub get_test_spec_is_valid() {
    my ($self, $test_name, $spec) = @_;
    
    #build url
    my $test_url = $self->url;
    chomp($test_url);
    $test_url .= "/" if($self->url !~ /\/$/);
    $test_url .= "tests/$test_name/spec/is-valid";
    
    #convert spec to string
    my $spec_str = to_json($spec);
    
    #fetch test
    my $test_response = send_http_request(
        connection_type => 'GET', 
        url => $test_url, 
        get_params => {'spec'=>$spec_str},
        timeout => $self->filters->timeout,
        ca_certificate_file => $self->filters->ca_certificate_file,
        ca_certificate_path => $self->filters->ca_certificate_path,
        verify_hostname => $self->filters->verify_hostname,
        local_address => $self->bind_address,
        bind_map => $self->bind_map,
        address_map => $self->lead_address_map,
    );
    if($test_response->code && $test_response->code == 404){
        $self->_set_error("pScheduler server does not recognize test of type '$test_name'");
        return;
    }elsif(!$test_response->is_success){
        my $msg = build_err_msg(http_response => $test_response);
        $self->_set_error($msg);
        return;
    }
    my $test_response_json = from_json($test_response->body);
    if(!$test_response_json){
        $self->_set_error("No validation object returned from $test_url");
        return;
    }elsif(!exists $test_response_json->{'valid'}){
        $self->_set_error("Returned validation object missing 'valid' field");
        return;
    }
    
    return $test_response_json;
}

sub get_archiver_is_valid() {
    my ($self, $archiver_name, $data) = @_;
    
    #build url
    my $test_url = $self->url;
    chomp($test_url);
    $test_url .= "/" if($self->url !~ /\/$/);
    $test_url .= "archivers/$archiver_name/data-is-valid";
    
    #convert spec to string
    my $data_str = to_json($data);
    
    #fetch test
    my $test_response = send_http_request(
        connection_type => 'GET', 
        url => $test_url, 
        get_params => {'data'=>$data_str},
        timeout => $self->filters->timeout,
        ca_certificate_file => $self->filters->ca_certificate_file,
        ca_certificate_path => $self->filters->ca_certificate_path,
        verify_hostname => $self->filters->verify_hostname,
        local_address => $self->bind_address,
        bind_map => $self->bind_map,
        address_map => $self->lead_address_map,
    );
    if($test_response->code == 404){
        $self->_set_error("pScheduler server does not recognize archiver of type '$archiver_name'");
        return;
    }elsif(!$test_response->is_success){
        my $msg = build_err_msg(http_response => $test_response);
        $self->_set_error($msg);
        return;
    }
    my $test_response_json = from_json($test_response->body);
    if(!$test_response_json){
        $self->_set_error("No validation object returned from $test_url");
        return;
    }elsif(!exists $test_response_json->{'valid'}){
        $self->_set_error("Returned validation object missing 'valid' field");
        return;
    }
    
    return $test_response_json;
}

sub get_context_is_valid() {
    my ($self, $context_name, $data) = @_;
    
    #build url
    my $test_url = $self->url;
    chomp($test_url);
    $test_url .= "/" if($self->url !~ /\/$/);
    $test_url .= "contexts/$context_name/data-is-valid";
    
    #convert spec to string
    my $data_str = to_json($data);
    
    #fetch test
    my $test_response = send_http_request(
        connection_type => 'GET', 
        url => $test_url, 
        get_params => {'data'=>$data_str},
        timeout => $self->filters->timeout,
        ca_certificate_file => $self->filters->ca_certificate_file,
        ca_certificate_path => $self->filters->ca_certificate_path,
        verify_hostname => $self->filters->verify_hostname,
        local_address => $self->bind_address,
        bind_map => $self->bind_map,
        address_map => $self->lead_address_map,
    );
    if($test_response->code == 404){
        $self->_set_error("pScheduler server does not recognize context of type '$context_name'");
        return;
    }elsif(!$test_response->is_success){
        my $msg = build_err_msg(http_response => $test_response);
        $self->_set_error($msg);
        return;
    }
    my $test_response_json = from_json($test_response->body);
    if(!$test_response_json){
        $self->_set_error("No validation object returned from $test_url");
        return;
    }elsif(!exists $test_response_json->{'valid'}){
        $self->_set_error("Returned validation object missing 'valid' field");
        return;
    }
    
    return $test_response_json;
}

sub get_hostname() {
    my $self = shift;
    
    #build url
    my $hostname_url = $self->url;
    chomp($hostname_url);
    $hostname_url .= "/" if($self->url !~ /\/$/);
    $hostname_url .= "hostname";
    
    my %filters = ();

    my $response = send_http_request(
        connection_type => 'GET', 
        url => $hostname_url, 
        timeout => $self->filters->timeout,
        ca_certificate_file => $self->filters->ca_certificate_file,
        ca_certificate_path => $self->filters->ca_certificate_path,
        verify_hostname => $self->filters->verify_hostname,
        local_address => $self->bind_address,
        bind_map => $self->bind_map,
        address_map => $self->lead_address_map,
        #headers => $self->filters->headers()
    );
     
    if(!$response->is_success){
        my $msg = build_err_msg(http_response => $response);
        $self->_set_error($msg);
        return;
    }

    my $response_json = from_json($response->body, {allow_nonref => 1});
    if(! $response_json){
        $self->_set_error("No hostname returned.");
        return;
    }
    
    return $response_json;
}

# curl -k "https://147.91.1.235/pscheduler/tests/rtt/participants?spec=%7B%22source-node%22:%22147.91.1.235%22,%22dest%22:%22147.91.27.4%22,%22source%22:%22147.91.1.235%22,%22ip-version%22:4,%22ttl%22:255,%22schema%22:1%7D"
sub get_test_is_multiparticipant {
    my ($self, $input_data) = @_;

    unless ($input_data) {
        # TODO: handle warning
        print "is_miltiparticipant_test: wrong test spec";
        return 0;
    }
    # $input_data: {"spec":{"ttl":255,"schema":1,"ip-version":4,"source":"147.91.1.235","source-node":"147.91.1.235","dest":"147.91.4.27"},"type":"rtt"}
    # $input_data: {"type":"throughput","spec":{"dest":"host-a.perfsonar.net","source":"host-c.perfsonar.net","duration":"PT30S"}}

    #build url
    my $test_url = $self->url;
    chomp($test_url);
    $test_url .= "/" if($self->url !~ /\/$/);
    my $test_type = decode_json($input_data)->{'type'}; # "rtt";
    my $test_spec = encode_json(decode_json($input_data)->{'spec'}); # {"spec":{"ttl":255,"schema":1,"ip-version":4,"source":"147.91.1.235","source-node":"147.91.1.235","dest":"147.91.4.27"},"type":"rtt"};

    $test_url = $test_url . $test_type ."/participants?spec=" . $test_spec;
    my $encoder = URI::Encode->new({encode_reserved => 0});
    my $test_spec_url = $encoder->encode($test_url);

    my $response = send_http_request(
        connection_type => 'GET',
        url => $test_spec_url,
        get_params => {},
        timeout => $self->filters->timeout,
        ca_certificate_file => $self->filters->ca_certificate_file,
        ca_certificate_path => $self->filters->ca_certificate_path,
        verify_hostname => $self->filters->verify_hostname,
        local_address => $self->bind_address,
        bind_map => $self->bind_map,
        address_map => $self->lead_address_map,
    );

    unless($response->is_success){
        my $msg = build_err_msg(http_response => $response);
        $self->_set_error($msg);
        return;
    }
    
    my $participants_json = from_json($response->body);
    unless ($participants_json){
        $self->_set_error("No participants returned.");
        return;
    }

    my $count = 0;
    if (ref($participants_json) eq 'HASH') {
        my $participants_array = $participants_json->{'participants'};
        $count = @$participants_array;
    }
    if ($count > 1) {
        return 1;
    } else {
        return 0;
    }
}

__PACKAGE__->meta->make_immutable;

1;