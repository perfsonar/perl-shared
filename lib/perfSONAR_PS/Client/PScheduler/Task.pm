package perfSONAR_PS::Client::PScheduler::Task;

use Mouse;
use JSON qw(to_json from_json);
use perfSONAR_PS::Client::Utils qw(send_http_request build_err_msg extract_url_uuid);
use perfSONAR_PS::Client::PScheduler::Archive;
use perfSONAR_PS::Client::PScheduler::Run;
use Digest::MD5 qw(md5_base64);

extends 'perfSONAR_PS::Client::PScheduler::BaseNode';

override '_post_url' => sub {
    my $self = shift;
    my $tasks_url = $self->url;
    chomp($tasks_url);
    $tasks_url .= "/" if($self->url !~ /\/$/);
    $tasks_url .= "tasks";
    return $tasks_url;
};

sub schema{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'schema'} = $val;
    }
    return $self->data->{'schema'};
}

sub test_type{
    my ($self, $val) = @_;
    if(defined $val){
        $self->_init_field($self->data, 'test');
        $self->data->{'test'}->{'type'} = $val;
    }
    unless($self->_has_field($self->data, "test")){
        return undef;
    }
    return $self->data->{'test'}->{'type'};
}

sub test_spec{
    my ($self, $val) = @_;
    if(defined $val){
        $self->_init_field($self->data, 'test');
        $self->data->{'test'}->{'spec'} = $val;
    }
    unless($self->_has_field($self->data, "test")){
        return undef;
    }
    return $self->data->{'test'}->{'spec'};
}

sub test_spec_param{
    my ($self, $field, $val) = @_;
    unless(defined $field){
        return undef;
    }
    if(defined $val){
        $self->_init_field($self->data, 'test');
        $self->_init_field($self->data->{'test'}, 'spec');
        $self->data->{'test'}->{'spec'}->{$field} = $val;
    }
    unless($self->_has_field($self->data, "test") &&
            $self->_has_field($self->data->{'test'}, "spec")){
        return undef;
    }
    return $self->data->{'test'}->{'spec'}->{$field};
}


sub tool{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'tool'} = $val;
    }
    return $self->data->{'tool'};
}

sub reference{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->data->{'reference'} = $val;
    }
    
    return $self->data->{'reference'};
}

sub reference_param{
    my ($self, $field, $val) = @_;
    
    unless(defined $field){
        return undef;
    }
    
    if(defined $val){
        $self->_init_field($self->data, 'reference');
        $self->data->{'reference'}->{$field} = $val;
    }
    
    unless($self->_has_field($self->data, "reference")){
        return undef;
    }
    
    return $self->data->{'reference'}->{$field};
}

sub schedule{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->data->{'schedule'} = $val;
    }
    
    return $self->data->{'schedule'};
}

sub schedule_maxruns{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->_init_field($self->data, 'schedule');
        $self->data->{'schedule'}->{'max-runs'} = $val;
    }
    
    unless($self->_has_field($self->data, "schedule")){
        return undef;
    }
    
    return $self->data->{'schedule'}->{'max-runs'};
}

sub schedule_repeat{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->_init_field($self->data, 'schedule');
        $self->data->{'schedule'}->{'repeat'} = $val;
    }
    
    unless($self->_has_field($self->data, "schedule")){
        return undef;
    }
    
    return $self->data->{'schedule'}->{'repeat'};
}

sub schedule_randslip{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->_init_field($self->data, 'schedule');
        $self->data->{'schedule'}->{'randslip'} = $val;
    }
    
    unless($self->_has_field($self->data, "schedule")){
        return undef;
    }
    
    return $self->data->{'schedule'}->{'randslip'};
}

sub schedule_slip{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->_init_field($self->data, 'schedule');
        $self->data->{'schedule'}->{'slip'} = $val;
    }
    
    unless($self->_has_field($self->data, "schedule")){
        return undef;
    }
    
    return $self->data->{'schedule'}->{'slip'};
}

sub schedule_start{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->_init_field($self->data, 'schedule');
        $self->data->{'schedule'}->{'start'} = $val;
    }
    
    unless($self->_has_field($self->data, "schedule")){
        return undef;
    }
    
    return $self->data->{'schedule'}->{'start'};
}

sub schedule_until{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->_init_field($self->data, 'schedule');
        $self->data->{'schedule'}->{'until'} = $val;
    }
    
    unless($self->_has_field($self->data, "schedule")){
        return undef;
    }
    
    return $self->data->{'schedule'}->{'until'};
}

sub archives{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->data->{'archives'} = [];
        foreach my $v(@{$val}){
            push @{$self->data->{'archives'}}, {
                'archiver' => $v->name(),
                'data' => $v->data(),
            };
        }
    }
    
    my @archives = ();
    foreach my $archive(@{$self->data->{'archives'}}){
        push @archives, new perfSONAR_PS::Client::PScheduler::Archive(
            'name' => $archive->{'archiver'},
            'data' => $archive->{'data'},
        );
    }
    
    return \@archives;
}

sub add_archive{
    my ($self, $val) = @_;
    
    unless(defined $val){
        return;
    }
    
    unless($self->data->{'archives'}){
        $self->data->{'archives'} = [];
    }
    
    push @{$self->data->{'archives'}}, {
            'archiver' =>  $val->name(),
            'data' =>  $val->data()
        };
}

sub requested_tools{
    my ($self, $val) = @_;
    
    #when requesting its tools, after posting its just tool
    if(defined $val){
        $self->data->{'tools'} = $val;
    }
    
   return $self->data->{'tools'};
}

sub add_requested_tool{
    my ($self, $val) = @_;
    
    unless(defined $val){
        return;
    }
    
    unless($self->data->{'tools'}){
        $self->data->{'tools'} = [];
    }
    
    push @{$self->data->{'tools'}}, $val;
}

sub post_task {
    my $self = shift;
    
    #init some required fields
    $self->schema(1) unless($self->schema());
    $self->_init_field($self->data, 'schedule');
    $self->_init_field($self->data, 'test');
    $self->_init_field($self->data->{'test'}, 'spec');
    $self->data->{'test'}->{'spec'}->{'schema'} = 1 unless($self->data->{'test'}->{'spec'}->{'schema'}); 
    
    #send request
    my $content = $self->_post(to_json($self->data));
    return -1 if($self->error);
    if(!$content){
        $self->_set_error("No task URL returned by post");
        return -1;
    }
    
    my $task_uuid = extract_url_uuid(url => $content);
    if($task_uuid){
        $self->uuid($task_uuid);
    }else{
        $self->_set_error("Unable to determine UUID.");
        return -1;
    }
    
    return 0;
}

sub delete_task {
    my $self = shift;
        
    #send request
    my $content = $self->_delete();
    return -1 if($self->error);
    return 0;
}

sub runs(){
    my $self = shift;
    
    #build url
    my $runs_url = $self->url;
    chomp($runs_url);
    $runs_url .= "/" if($self->url !~ /\/$/);
    $runs_url .= "tasks/" . $self->uuid() . "/runs";
    
    my %filters = ();
    my $response = send_http_request(
        connection_type => 'GET', 
        url => $runs_url, 
        timeout => $self->filters->timeout,
        ca_certificate_file => $self->filters->ca_certificate_file,
        ca_certificate_path => $self->filters->ca_certificate_path,
        verify_hostname => $self->filters->verify_hostname,
        #headers => $self->filters->headers()
    );
     
    if(!$response->is_success){
        my $msg = build_err_msg(http_response => $response);
        $self->_set_error($msg);
        return;
    }
    my $response_json = from_json($response->content);
    if(! $response_json){
        $self->_set_error("No run objects returned.");
        return;
    }
    if(ref($response_json) ne 'ARRAY'){
        $self->_set_error("Runs must be an array not " . ref($response_json));
        return;
    }
    
    my @runs = ();
    foreach my $run_url(@{$response_json}){
        my $run_uuid = extract_url_uuid(url => $run_url);
        unless($run_uuid){
            $self->_set_error("Unable to extract name from url $run_url");
            return;
        }
        my $run = $self->get_run($run_uuid);
        unless($run){
            #there was an error
            return;
        }
        push @runs, $run;
    }
    
    return \@runs;
}

sub run_uuids(){
    my $self = shift;
    
    #build url
    my $runs_url = $self->url;
    chomp($runs_url);
    $runs_url .= "/" if($self->url !~ /\/$/);
    $runs_url .= "tasks/" . $self->uuid() . "/runs";
    
    my %filters = ();
    my $response = send_http_request(
        connection_type => 'GET', 
        url => $runs_url, 
        timeout => $self->filters->timeout,
        ca_certificate_file => $self->filters->ca_certificate_file,
        ca_certificate_path => $self->filters->ca_certificate_path,
        verify_hostname => $self->filters->verify_hostname,
        #headers => $self->filters->headers()
    );
     
    if(!$response->is_success){
        my $msg = build_err_msg(http_response => $response);
        $self->_set_error($msg);
        return;
    }
    my $response_json = from_json($response->content);
    if(! $response_json){
        $self->_set_error("No run objects returned.");
        return;
    }
    if(ref($response_json) ne 'ARRAY'){
        $self->_set_error("Runs must be an array not " . ref($response_json));
        return;
    }
    
    my @runs = ();
    foreach my $run_url(@{$response_json}){
        my $run_uuid = extract_url_uuid(url => $run_url);
        unless($run_uuid){
            $self->_set_error("Unable to extract name from url $run_url");
            return;
        }
        push @runs, $run_uuid;
    }
    
    return \@runs;
}

sub get_run() {
    my ($self, $run_uuid) = @_;
    
    #build url
    my $run_url = $self->url;
    chomp($run_url);
    $run_url .= "/" if($self->url !~ /\/$/);
    $run_url .= "tasks/" . $self->uuid() . "/runs/$run_uuid";
    
    #fetch tool
    my $run_response = send_http_request(
        connection_type => 'GET', 
        url => $run_url, 
        timeout => $self->filters->timeout,
        ca_certificate_file => $self->filters->ca_certificate_file,
        ca_certificate_path => $self->filters->ca_certificate_path,
        verify_hostname => $self->filters->verify_hostname,
    );
    if(!$run_response->is_success){
        my $msg = build_err_msg(http_response => $run_response);
        $self->_set_error($msg);
        return;
    }
    my $run_response_json = from_json($run_response->content);
    if(!$run_response_json){
        $self->_set_error("No run object returned from $run_url");
        return;
    }
    
    return new perfSONAR_PS::Client::PScheduler::Run(data => $run_response_json, url => $run_url, filters => $self->filters, uuid => $run_uuid);
}

sub get_lead() {
    my ($self) = @_;
    
    #need a test type and test spec for this to work
    unless ($self->test_type() && $self->test_spec()){
        return;
    }
    
    #build url
    my $lead_url = $self->url;
    chomp($lead_url);
    $lead_url .= "/" if($self->url !~ /\/$/);
    $lead_url .= "tests/" . $self->test_type()  . "/lead";
    
    #fetch lead
    $self->data->{'test'}->{'spec'}->{'schema'} = 1 unless($self->data->{'test'}->{'spec'}->{'schema'}); 
    my %get_params = ("spec" => to_json($self->test_spec()));
    my $lead_response = send_http_request(
        connection_type => 'GET', 
        url => $lead_url, 
        get_params => \%get_params,
        timeout => $self->filters->timeout,
        ca_certificate_file => $self->filters->ca_certificate_file,
        ca_certificate_path => $self->filters->ca_certificate_path,
        verify_hostname => $self->filters->verify_hostname,
    );
    if(!$lead_response->is_success){
        my $msg = build_err_msg(http_response => $lead_response);
        $self->_set_error($msg);
        return;
    }
    my $lead_response_json;
    eval{$lead_response_json = from_json($lead_response->content, {allow_nonref => 1});};
    if($@){
        $self->_set_error("Error parsing lead object returned from $lead_url: $@");
        return;
    }
    
    return $lead_response_json;
}

sub get_lead_url() {
    my ($self, $scheme, $port, $path) = @_;
    
    # Defaults
    $scheme = 'https' unless($scheme);
    $port = $port ? ":$port" : '';
    $path = '/pscheduler' unless($path);
    $path = "/$path" unless($path =~ /^\//);
    
    #Get address
    my $address = $self->get_lead();
    return unless($address);
    
    return "${scheme}://${address}${port}${path}";
}

sub refresh_lead() {
    my ($self, $scheme, $port, $path) = @_;
    
    my $lead = $self->get_lead_url($scheme, $port, $path);
    if($lead){
        #if lead exists, change url, otherwise keep the same
        $self->url($lead);
    }
    
    return $lead;
}

sub checksum() {
    #calculates checksum for comparing tasks, ignoring stuff like UUID and lead url
    my ($self) = @_;
    
    #make sure these fields are consistent
    $self->schema(1) unless($self->schema());
    $self->data->{'test'}->{'spec'}->{'schema'} = 1 unless($self->data->{'test'}->{'spec'}->{'schema'}); 
    $self->data->{'archives'} = []  unless($self->data->{'archives'});
    $self->data->{'schedule'} = {}  unless($self->data->{'schedule'});
    
    #disable canonical since we don't care at the moment
    my $data_copy = from_json(to_json($self->data, {'canonical' => 0}));
    $data_copy->{'tool'} = ''; #clear out tool since set by server
    $data_copy->{'schedule'}->{'start'} = ''; #clear out temporal values
    $data_copy->{'schedule'}->{'until'} = ''; #clear out temporal values
    
    #canonical should keep it consistent by sorting keys
    return md5_base64(to_json($data_copy, {'canonical' => 1}));
}


__PACKAGE__->meta->make_immutable;

1;