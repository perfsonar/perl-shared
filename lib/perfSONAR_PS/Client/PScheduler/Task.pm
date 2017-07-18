package perfSONAR_PS::Client::PScheduler::Task;

use Mouse;
use JSON qw(to_json from_json);
use perfSONAR_PS::Client::Utils qw(send_http_request build_err_msg extract_url_uuid);
use perfSONAR_PS::Client::PScheduler::Archive;
use perfSONAR_PS::Client::PScheduler::Run;
use Digest::MD5 qw(md5_base64);
use Data::Validate::IP qw(is_loopback_ipv4);

extends 'perfSONAR_PS::Client::PScheduler::BaseNode';

has 'bind_map' => (is => 'rw', isa => 'HashRef', default => sub { {} });
has 'lead_bind_map' => (is => 'rw', isa => 'HashRef', default => sub { {} });
has 'lead_address_map' => (is => 'rw', isa => 'HashRef', default => sub { {} });

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

sub lead_bind{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'lead-bind'} = $val;
    }
    return $self->data->{'lead-bind'};
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

sub schedule_sliprand{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->_init_field($self->data, 'schedule');
        $self->data->{'schedule'}->{'sliprand'} = $val ? JSON::true : JSON::false;
    }
    
    unless($self->_has_field($self->data, "schedule")){
        return undef;
    }
    
    return $self->data->{'schedule'}->{'sliprand'};
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

sub detail{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->data->{'schedule'} = $val;
    }
    
    return $self->data->{'schedule'};
}

sub detail_enabled{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->_init_field($self->data, 'detail');
        $self->data->{'detail'}->{'enabled'} = $val ? JSON::true : JSON::false;
    }
    
    unless($self->_has_field($self->data, "detail")){
        return undef;
    }
    
    return $self->data->{'detail'}->{'enabled'};
}

sub detail_start{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->_init_field($self->data, 'detail');
        $self->data->{'detail'}->{'start'} = $val;
    }
    
    unless($self->_has_field($self->data, "detail")){
        return undef;
    }
    
    return $self->data->{'detail'}->{'start'};
}

sub detail_runs{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->_init_field($self->data, 'detail');
        $self->data->{'detail'}->{'runs'} = $val;
    }
    
    unless($self->_has_field($self->data, "detail")){
        return undef;
    }
    
    return $self->data->{'detail'}->{'runs'};
}

sub detail_added{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->_init_field($self->data, 'detail');
        $self->data->{'detail'}->{'added'} = $val;
    }
    
    unless($self->_has_field($self->data, "detail")){
        return undef;
    }
    
    return $self->data->{'detail'}->{'added'};
}

sub detail_slip{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->_init_field($self->data, 'detail');
        $self->data->{'detail'}->{'slip'} = $val;
    }
    
    unless($self->_has_field($self->data, "detail")){
        return undef;
    }
    
    return $self->data->{'detail'}->{'slip'};
}

sub detail_duration{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->_init_field($self->data, 'detail');
        $self->data->{'detail'}->{'duration'} = $val;
    }
    
    unless($self->_has_field($self->data, "detail")){
        return undef;
    }
    
    return $self->data->{'detail'}->{'duration'};
}

sub detail_participants{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->_init_field($self->data, 'detail');
        $self->data->{'detail'}->{'participants'} = $val;
    }
    
    unless($self->_has_field($self->data, "detail")){
        return undef;
    }
    
    return $self->data->{'detail'}->{'participants'};
}

sub detail_exclusive{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->_init_field($self->data, 'detail');
        $self->data->{'detail'}->{'exclusive'} = $val ? JSON::true : JSON::false;
    }
    
    unless($self->_has_field($self->data, "detail")){
        return undef;
    }
    
    return $self->data->{'detail'}->{'exclusive'};
}

sub detail_multiresult{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->_init_field($self->data, 'detail');
        $self->data->{'detail'}->{'multi-result'} = $val ? JSON::true : JSON::false;
    }
    
    unless($self->_has_field($self->data, "detail")){
        return undef;
    }
    
    return $self->data->{'detail'}->{'multi-result'};
}

sub detail_anytime{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->_init_field($self->data, 'detail');
        $self->data->{'detail'}->{'anytime'} = $val ? JSON::true : JSON::false;
    }
    
    unless($self->_has_field($self->data, "detail")){
        return undef;
    }
    
    return $self->data->{'detail'}->{'anytime'};
}

sub archives{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->data->{'archives'} = [];
        foreach my $v(@{$val}){
            my $tmp_archive = {
                'archiver' => $v->name(),
                'data' => $v->data(),
            };
            $tmp_archive->{'ttl'} = $v->ttl() if(defined $v->ttl());
            push @{$self->data->{'archives'}}, $tmp_archive;
        }
    }
    
    my @archives = ();
    foreach my $archive(@{$self->data->{'archives'}}){
        my $tmp_archive_obj = new perfSONAR_PS::Client::PScheduler::Archive(
            'name' => $archive->{'archiver'},
            'data' => $archive->{'data'},
        );
        $tmp_archive_obj->ttl($archive->{'ttl'}) if(exists $archive->{'ttl'} && defined $archive->{'ttl'});
        push @archives, $tmp_archive_obj;
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
    
    my $tmp_archive = {
            'archiver' =>  $val->name(),
            'data' =>  $val->data()
        };
    $tmp_archive->{'ttl'} = $val->ttl() if(defined $val->ttl());
    push @{$self->data->{'archives'}}, $tmp_archive;
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

sub add_bind_map{
    my ($self, $target, $bind) = @_;
    
    unless(defined $target && defined $bind){
        return;
    }
    
    $self->bind_map->{$target} = $bind;
}

sub add_lead_bind_map{
    my ($self, $target, $bind) = @_;
    
    unless(defined $target && defined $bind){
        return;
    }
    
    $self->lead_bind_map->{$target} = $bind;
}

sub add_lead_address_map{
    my ($self, $target, $addr) = @_;
    
    unless(defined $target && defined $addr){
        return;
    }
    
    $self->lead_address_map->{$target} = $addr;
}

sub add_local_bind_map{
    my ($self, $bind) = @_;
    
    unless(defined $bind){
        return;
    }
    
    $self->bind_map->{'_default'} = $bind;
}

sub add_local_lead_bind_map{
    my ($self, $bind) = @_;
    
    unless(defined $bind){
        return;
    }
    
    $self->lead_bind_map->{'_default'} = $bind;
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
        local_address => $self->bind_address,
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
        local_address => $self->bind_address,
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
        local_address => $self->bind_address,
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
    
    #do any address-based mappings here
    my $participants_lead_bind = "";
    if($self->url){
        my $url_obj = new URI($self->url);  
        my $lead = $url_obj->host;
        #map the URL to a specific public address if needed
        if(exists $self->lead_address_map->{$lead} && $self->lead_address_map->{$lead}){
            $url_obj->host($self->lead_address_map->{$lead});
            $self->url("$url_obj");
            $lead = $url_obj->host;
        }
        #init bindings if we haven't already done so
        if($self->needs_bind_addresses()){   
            #set bind map
            if(exists $self->bind_map->{$lead} && $self->bind_map->{$lead}){
                $self->bind_address($self->bind_map->{$lead});
            }elsif(exists $self->bind_map->{'_default'} && $self->bind_map->{'_default'}){
                $self->bind_address($self->bind_map->{'_default'}) unless(is_loopback_ipv4($lead) || $lead eq '::1' || $lead =~ /^localhost/);
            }
            #set participants lead
            if(exists $self->lead_bind_map->{$lead} && $self->lead_bind_map->{$lead}){
                $participants_lead_bind = $self->lead_bind_map->{$lead};
            }elsif(exists $self->lead_bind_map->{'_default'} && $self->lead_bind_map->{'_default'}){
                #Only do this if url points to local pscheduler - may cause problems if default assist server in .conf is remote
                $participants_lead_bind = $self->lead_bind_map->{'_default'} if(is_loopback_ipv4($lead) || $lead eq '::1' || $lead =~ /^localhost/);
            }
        }elsif($self->lead_bind()){
            #if lead_bind already set, give it to participants
            $participants_lead_bind = $self->lead_bind();
        }
        
        #map the URL to a specific public address if needed
        if(exists $self->lead_address_map->{$lead} && $self->lead_address_map->{$lead}){
            $url_obj->host($self->lead_address_map->{$lead});
            $self->url("$url_obj");
        }
    }
    
    #build url
    my $lead_url = $self->url;
    chomp($lead_url);
    $lead_url .= "/" if($self->url !~ /\/$/);
    $lead_url .= "tests/" . $self->test_type()  . "/participants";
    
    #fetch lead
    $self->data->{'test'}->{'spec'}->{'schema'} = 1 unless($self->data->{'test'}->{'spec'}->{'schema'}); 
    my %get_params = ("spec" => to_json($self->test_spec()));
    $get_params{'lead-bind'} =  $participants_lead_bind if($participants_lead_bind);
    my $lead_response = send_http_request(
        connection_type => 'GET', 
        url => $lead_url, 
        get_params => \%get_params,
        timeout => $self->filters->timeout,
        ca_certificate_file => $self->filters->ca_certificate_file,
        ca_certificate_path => $self->filters->ca_certificate_path,
        verify_hostname => $self->filters->verify_hostname,
        local_address => $self->bind_address,
    );
    if(!$lead_response->is_success){
        my $msg = build_err_msg(http_response => $lead_response);
        $self->_set_error($msg);
        return;
    }
    my $lead_response_json;
    eval{$lead_response_json = from_json($lead_response->content);};
    if($@){
        $self->_set_error("Error parsing lead object returned from $lead_url: $@");
        return;
    }
    unless($lead_response_json && exists $lead_response_json->{participants} && $lead_response_json->{participants}){
        $self->_set_error("Error parsing lead object returned from $lead_url: No participant list returned");
        return;
    }
    unless(@{$lead_response_json->{participants}} > 0){
        $self->_set_error("Error parsing lead object returned from $lead_url: No participants provided in returned list");
        return;
    }
    
    
    my $lead = $lead_response_json->{participants}->[0];
    
    #switch to public address if have mapping
    if($lead  && exists $self->lead_address_map->{$lead} && $self->lead_address_map->{$lead}){
        $lead = $self->lead_address_map->{$lead};
    }
        
    #set bind address if we have a bind map populated
    if($lead && exists $self->bind_map->{$lead} && $self->bind_map->{$lead}){
        $self->bind_address($self->bind_map->{$lead});
    }elsif(exists $self->bind_map->{'_default'} && $self->bind_map->{'_default'}){
        $self->bind_address($self->bind_map->{'_default'});
    }
    
    #set lead bind address if we have map set - only set it if we are local (first participant None) or explicitly call out address
    if($lead && exists $self->lead_bind_map->{$lead} && $self->lead_bind_map->{$lead}){
        $self->lead_bind($self->lead_bind_map->{$lead});
    }elsif(!$lead && exists $self->lead_bind_map->{'_default'} && $self->lead_bind_map->{'_default'}){
        $self->lead_bind($self->lead_bind_map->{'_default'});
    }
    
    return $lead;
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

sub needs_bind_addresses() {
    my ($self) = @_;
    
    if(%{$self->bind_map} && !$self->bind_address()){
        return 1;
    }
    
    if(%{$self->lead_bind_map} && !$self->lead_bind()){
        return 1;
    }
    
    return 0;
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
    my $data_copy = from_json(to_json($self->data, {canonical => 0, utf8 => 1}));
    $data_copy->{'tool'} = ''; #clear out tool since set by server
    $data_copy->{'schedule'}->{'start'} = ''; #clear out temporal values
    $data_copy->{'schedule'}->{'until'} = ''; #clear out temporal values
    $data_copy->{'detail'} = {}; #clear out detail
    #clear our private fields that won't get displayed by remote tasks
    foreach my $archive(@{$data_copy->{'archives'}}){
        foreach my $datum(keys %{$archive->{'data'}}){
            if($datum =~ /^_/){
                $archive->{'data'}->{$datum} = '';
            }
        }
    }
    
    #canonical should keep it consistent by sorting keys
    return md5_base64(to_json($data_copy, {canonical => 1, utf8 => 1}));
}

sub to_str() {
    my ($self) = @_;

    my $str = $self->test_type();
    $str .= "/" . $self->tool() if $self->tool();
    $str .= "(" . ($self->test_spec_param("source") ? $self->test_spec_param("source") : 'self');
    $str .= "->" . ($self->test_spec_param("dest") ?  $self->test_spec_param("dest") : $self->test_spec_param("destination"));
    $str .= ")";

    return $str;
}

__PACKAGE__->meta->make_immutable;

1;
