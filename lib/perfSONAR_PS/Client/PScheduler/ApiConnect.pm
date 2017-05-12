package perfSONAR_PS::Client::PScheduler::ApiConnect;

=head1 NAME

perfSONAR_PS::Client::PScheduler::ApiConnect - A client for interacting with pScheduler

=head1 DESCRIPTION

A client for interacting with pScheduler

=cut

use Mouse;
use Params::Validate qw(:all);
use perfSONAR_PS::Client::Utils qw(send_http_request build_err_msg extract_url_uuid);
use JSON qw(from_json to_json);

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
    
    my %filters = ();
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
    my $response_json = from_json($response->content);
    if(! $response_json){
        $self->_set_error("No task objects returned.");
        return;
    }
    if(ref($response_json) ne 'ARRAY'){
        $self->_set_error("Tasks must be an array not " . ref($response_json));
        return;
    }
    
    my @tasks = ();
    foreach my $task_url(@{$response_json}){
        my $task_uuid = extract_url_uuid(url => $task_url);
        unless($task_uuid){
            $self->_set_error("Unable to extract UUID from url $task_url");
            return;
        }
        my $task = $self->get_task($task_uuid);
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
    my $task_response_json = from_json($task_response->content);
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
    my $response_json = from_json($response->content);
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
    my $tool_response_json = from_json($tool_response->content);
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
    my $response_json = from_json($response->content);
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
    my $response_json = from_json($response->content);
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
    my $test_response_json = from_json($test_response->content);
    if(!$test_response_json){
        $self->_set_error("No test object returned from $test_url");
        return;
    }
    
    return new perfSONAR_PS::Client::PScheduler::Test(data => $test_response_json, url => $test_url, filters => $self->filters, uuid => $test_name);
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

    my $response_json = from_json($response->content, {allow_nonref => 1});
    if(! $response_json){
        $self->_set_error("No hostname returned.");
        return;
    }
    
    return $response_json;
}

__PACKAGE__->meta->make_immutable;

1;