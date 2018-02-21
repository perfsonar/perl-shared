package perfSONAR_PS::Client::PScheduler::TaskManager;

=head1 NAME

perfSONAR_PS::Client::PScheduler::TaskManager - A client tracking and maintaining pScheduler tasks across multiple servers

=head1 DESCRIPTION

A client for interacting with pScheduler

=cut

use Mouse;
use Params::Validate qw(:all);
use JSON qw(from_json to_json decode_json);
use Log::Log4perl::Logger;

use perfSONAR_PS::Client::PScheduler::ApiConnect;
use perfSONAR_PS::Client::PScheduler::ApiFilters;
use perfSONAR_PS::Client::PScheduler::Task;
use perfSONAR_PS::Utils::Logging;
use Data::UUID;
use DateTime::Format::ISO8601;
use DateTime;

use Data::Dumper;

our $VERSION = 4.0;

has 'pscheduler_url'      => (is => 'rw', isa => 'Str');
has 'reference_label'      => (is => 'rw', isa => 'Str');
has 'tracker_file'        => (is => 'rw', isa => 'Str');
has 'client_uuid_file'    => (is => 'rw', isa => 'Str');
has 'user_agent'          => (is => 'rw', isa => 'Str');
has 'new_task_min_ttl' => (is => 'rw', isa => 'Int');
has 'new_task_min_runs' => (is => 'rw', isa => 'Int');
has 'old_task_deadline'   => (is => 'rw', isa => 'Int');
has 'task_renewal_fudge_factor'  => (is => 'rw', isa => 'Num', default => 0.0);

has 'new_tasks'           => (is => 'rw', isa => 'ArrayRef[perfSONAR_PS::Client::PScheduler::Task]', default => sub{ [] });
has 'existing_task_map'   => (is => 'rw', isa => 'HashRef', default => sub{ {} });
has 'existing_archives' => (is => 'rw', isa => 'HashRef', default => sub{ {} });
has 'leads'               => (is => 'rw', isa => 'HashRef', default => sub{ {} });
has 'errors'              => (is => 'rw', isa => 'ArrayRef', default => sub{ [] });
has 'deleted_tasks'       => (is => 'rw', isa => 'ArrayRef[perfSONAR_PS::Client::PScheduler::Task]', default => sub{ [] });
has 'added_tasks'         => (is => 'rw', isa => 'ArrayRef[perfSONAR_PS::Client::PScheduler::Task]', default => sub{ [] });
has 'created_by'          => (is => 'rw', isa => 'HashRef', default => sub{ {} });
has 'leads_to_keep'       => (is => 'rw', isa => 'HashRef', default => sub{ {} });
has 'new_archives'        => (is => 'rw', isa => 'HashRef', default => sub{ {} });
has 'debug'               => (is => 'rw', isa => 'Bool');
has 'logger'              => (is => 'rw', isa => 'Log::Log4perl::Logger');
has 'logf'                => (is => 'ro', isa => 'perfSONAR_PS::Utils::Logging', writer => '_set_logf', default => sub{ new perfSONAR_PS::Utils::Logging() });

sub init {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {
                                            pscheduler_url => 1,
                                            tracker_file => 1,
                                            client_uuid_file => 1,
                                            reference_label => 1,
                                            user_agent => 1,
                                            new_task_min_ttl => 1,
                                            new_task_min_runs => 1,
                                            old_task_deadline => 1,
                                            bind_map => 1,
                                            lead_address_map => 1,
                                            task_renewal_fudge_factor => 0,
                                            debug => 0
                                        } );
    #init this object
    $self->errors([]);
    $self->pscheduler_url($parameters->{'pscheduler_url'});
    $self->reference_label($parameters->{'reference_label'});
    $self->tracker_file($parameters->{'tracker_file'});
    $self->client_uuid_file($parameters->{'client_uuid_file'});
    $self->user_agent($parameters->{'user_agent'});
    $self->created_by($self->_created_by());
    $self->new_task_min_ttl($parameters->{'new_task_min_ttl'});
    $self->new_task_min_runs($parameters->{'new_task_min_runs'});
    $self->old_task_deadline($parameters->{'old_task_deadline'});
    $self->task_renewal_fudge_factor($parameters->{'task_renewal_fudge_factor'}) if($parameters->{'task_renewal_fudge_factor'});
    $self->debug($parameters->{'debug'}) if($parameters->{'debug'});
    
    #get list of leads
    my $tracker_file_json = $self->_read_json_file($self->tracker_file());
    my $psc_leads = $tracker_file_json->{'leads'} ? $tracker_file_json->{'leads'} : {};
    $self->leads($psc_leads);
    $self->_update_lead($self->pscheduler_url(), {}); #init local url
    
    #get list of existing MAs
    my $tracked_archives = $tracker_file_json->{'archives'} ? $tracker_file_json->{'archives'} : {};
    $self->existing_archives($tracked_archives);
    
    #build list of existing tasks
    $self->logf()->global_context({"action" => "list"});
    my $bind_map = $parameters->{'bind_map'};
    
    ##
    # NOTE: I don't think we need lead_address_map here anymore, but may be wrong. Keep code for now
    # but may want to remove this to ease confusion in future.
    my $lead_address_map = $parameters->{'lead_address_map'};
    
    my %visited_leads = ();
    foreach my $psc_url(keys %{$self->leads()}){
        my $log_ctx = {'url' => $psc_url};
        $self->log_info("Getting task list from $psc_url", $log_ctx);
        #Query lead
        my $psc_lead = $self->leads()->{$psc_url};
        my $existing_task_map = {};
        my $psc_filters = new perfSONAR_PS::Client::PScheduler::ApiFilters();
        $psc_filters->detail_enabled(1);
        $psc_filters->reference_param($self->reference_label(), { "created-by" => $self->created_by() });
        my $psc_client = new perfSONAR_PS::Client::PScheduler::ApiConnect(url => $psc_url, filters => $psc_filters, bind_map => $bind_map, lead_address_map => $lead_address_map);
        
        #get hostname to see if this is a server we already visited using a different address
        my $psc_hostname = $psc_client->get_hostname();
        if($psc_client->error()){
            $self->log_error("Error getting hostname from $psc_url: " . $psc_client->error(), $log_ctx);
            $psc_lead->{'error_time'} = time; 
            push @{$self->errors()}, "Problem retrieving host information from pScheduler lead $psc_url: ".$psc_client->error();
            next;
        }elsif(!$psc_hostname){
            $self->log_error("Error: $psc_url returned an empty hostname", $log_ctx );
            $psc_lead->{'error_time'} = time; 
            push @{$self->errors()}, "Empty string returned from $psc_url/hostname. It may not have its hostname configured correctly.";
            next;
        }elsif($visited_leads{$psc_hostname}){
            $self->log_debug("Already visited server at $psc_url using " . $visited_leads{$psc_hostname} . ", so skipping.", $log_ctx);
            next;
        }else{
           $visited_leads{$psc_hostname} = $psc_url;
        }
        
        #get tasks
        my $existing_tasks = $psc_client->get_tasks();
        if($existing_tasks && @{$existing_tasks} > 0 && $psc_client->error()){
            #there was an error getting an individual task
             $self->log_error("Error fetching an individual task, but was able to get list: " .  $psc_client->error(), $log_ctx);
        }elsif($psc_client->error()){
            #there was an error getting the entire list
            $self->log_error("Error getting task list from $psc_url: " . $psc_client->error(), $log_ctx);
            $psc_lead->{'error_time'} = time; 
            push @{$self->errors()}, "Problem getting existing tests from pScheduler lead $psc_url: ".$psc_client->error();
            next;
        }elsif(@{$existing_tasks} == 0){
            #TODO: Drop this when 4.0 deprecated. fallback in case detail filter not supported (added in 4.0.2).
            $self->log_debug("Trying to get task list without enabled filter", $log_ctx);
            delete $psc_client->filters()->task_filters()->{"detail"};
            $existing_tasks = $psc_client->get_tasks();
            if($psc_client->error()){
                #there was an error getting the entire list
                $self->log_error("Error getting task list (no enabled filter) from $psc_url: " . $psc_client->error(), $log_ctx);
                $psc_lead->{'error_time'} = time; 
                push @{$self->errors()}, "Problem getting existing tests from pScheduler lead $psc_url: ".$psc_client->error();
                next;
            }
        }
        
        #Add to existing task map
        foreach my $existing_task(@{$existing_tasks}){
            next unless($existing_task->detail_enabled()); #skip disabled tests
            $self->log_task($existing_task);
            #make an array since could have more than one test with same checksum
            $self->existing_task_map()->{$existing_task->checksum()} = {} unless($self->existing_task_map()->{$existing_task->checksum()});
            $self->existing_task_map()->{$existing_task->checksum()}->{$existing_task->tool()} = {} unless($self->existing_task_map()->{$existing_task->checksum()}->{$existing_task->tool()});
            $self->existing_task_map()->{$existing_task->checksum()}->{$existing_task->tool()}->{$existing_task->uuid()} = {
                    'task' => $existing_task,
                    'keep' => 0
                } ;
        }
    }  
}

sub add_task {
    my ($self, @args) = @_;
    
    $self->logf()->global_context({"action" => "add_to_manager"});
    my $parameters = validate( @args, {task => 1, local_address => 0, repeat_seconds => 0 } );
    my $new_task = $parameters->{task};
    my $local_address = $parameters->{local_address};
    my $repeat_seconds = $parameters->{repeat_seconds};
    
    #set reference params
    ##need to copy this so different addresses don't break checksum
    my $tmp_created_by = {};
    $tmp_created_by->{'address'} = $local_address if($local_address);
    foreach my $cp(keys %{$self->created_by()}){
        $tmp_created_by->{$cp} = $self->created_by()->{$cp};
    }
    $new_task->reference_param($self->reference_label(), { "created-by" => $tmp_created_by });
    
    #determine if we need new task and create
    my($need_new_task, $new_task_start) = $self->_need_new_task($new_task);
    if($need_new_task){
        #task does not exist, we need to create it
        $new_task->schedule_start($self->_ts_to_iso($new_task_start));
        #set end time to greater of min repeats and expiration time
        my $min_repeat_time = 0;
        if($repeat_seconds){
            # a bit hacky, but trying to convert an ISO duration to seconds is both imprecise 
            # and expensive so just use given value since these generally start out as 
            # seconds anyways.
            $min_repeat_time = $repeat_seconds * $self->new_task_min_runs();
        }
        #use new start time if exists, otherwise start with current time
        my $new_until = $new_task_start ? $new_task_start: time;
        if($min_repeat_time > $self->new_task_min_ttl()){
            #if the minimum number of repeats is longer than the min ttl, use the greater value
            $new_until += $min_repeat_time;
        }else{
            #just add the minimum ttl
            $new_until += $self->new_task_min_ttl();
        }
        $new_task->schedule_until($self->_ts_to_iso($new_until));
        
        push @{$self->new_tasks()}, $new_task;
    }
}

sub commit {
    my ($self) = @_;
    
    $self->errors([]);
    
    $self->_delete_tasks();
    $self->_create_tasks();
    $self->_cleanup_leads();
    $self->_write_tracker_file();
}

sub check_assist_server {
    my ($self) = @_;
    $self->logf()->global_context({"action" => "check_assist_server", "url" =>  $self->pscheduler_url()});
    
    my $psc_client = new perfSONAR_PS::Client::PScheduler::ApiConnect(url => $self->pscheduler_url());
    $psc_client->get_test_urls();
    if($psc_client->error()){
        $self->log_error("Error checking assist server: " . $psc_client->error());
        return 0;
    }
    
    return 1;
}

sub _delete_tasks {
    my ($self) = @_;
    
    $self->logf()->global_context({"action" => "delete"});

    #clear out previous deleted tasks
    $self->deleted_tasks([]);
    
    $self->log_info("Deleting tasks");
    my $found_task_to_delete = 0;
    foreach my $checksum(keys %{$self->existing_task_map()}){
        my $cached_lead;
        my $cached_bind;
        my $cmap = $self->existing_task_map()->{$checksum};
        foreach my $tool(keys %{$cmap}){
            my $tmap = $cmap->{$tool};
            foreach my $uuid(keys %{$tmap}){
                #prep task
                my $meta_task = $tmap->{$uuid};
                my $task = $meta_task->{'task'};
                #optimization so don't lookup lead for same params
                if($cached_lead){
                    $task->url($cached_lead);
                    $task->bind_address($cached_bind) if($cached_bind);
                }else{
                    $cached_lead = $task->refresh_lead();
                    $cached_bind = $task->bind_address();
                }
                if($task->error){
                    my $err = sprintf("Problem determining which pscheduler to submit test to for deletion, skipping test %s: %s", $task->to_str, $task->error);
                    $self->log_error($err);
                    push @{$self->errors()}, $err;
                    next;
                }
                
                #if we keep, make sure we track lead, otherwise delete
                if($meta_task->{'keep'}){
                    #make sure we keep the lead around
                    $self->leads_to_keep()->{$task->url()} = 1;
                }else{
                    $self->log_task($task);
                    $found_task_to_delete = 1;
                    $task->delete_task();
                    if($task->error()){
                        $self->leads_to_keep()->{$task->url()} = 1;
                        $self->_update_lead($task->url(), {'error_time' => time});
                        my $err = sprintf("Problem deleting test %s, continuing with rest of config: %s", $task->to_str, $task->error);
                        $self->log_error($err);
                        push @{$self->errors()}, $err;
                    }else{
                        push @{$self->deleted_tasks()}, $task;
                    }                  
                }
            }
        }
    }
    $self->log_info("No tasks marked for deletion") unless($found_task_to_delete);
    $self->log_info("Done deleting tasks");
}

sub _need_new_task {
    my ($self, $new_task) = @_;
    
    my $existing = $self->existing_task_map();
    
    #if we use one of bind address maps, we have to refresh the lead here or else the 
    #checksum will be wrong. If we don't specify then don't worry about it as its a 
    #performance hit
    if($new_task->needs_bind_addresses()){
        $new_task->refresh_lead();
    }
    
    #if private ma params change, then need new task
    #also update new_archives here so we don't have to re-calculate all the checksums
    my $ma_changed = 0;
    foreach my $archive(@{$new_task->archives()}){
        my $opaque_new_checksum = $archive->checksum();
        my $old_checksum = $self->existing_archives()->{$opaque_new_checksum};
        my $new_checksum = $archive->checksum(include_private => 1);
        $self->new_archives()->{$opaque_new_checksum} = $new_checksum;
        if(!$old_checksum || $old_checksum ne $new_checksum){
            $ma_changed = 1;
        }
    }
    
    #if no matching checksum, then does not exist
    if($ma_changed || !$existing->{$new_task->checksum()}){
        return (1, undef);
    }
    
    #if matching checksum, and tool is not defined on new task then we match
    my $need_new_task = 1;
    my $new_start_time;
    if(!$new_task->requested_tools()){
        my $cmap = $existing->{$new_task->checksum()};
        foreach my $tool(keys %{$cmap}){
            ($need_new_task, $new_start_time) = $self->_evaluate_task($cmap->{$tool}, $need_new_task, $new_start_time);
        }
    }else{
        #we have a matching checksum and we have an explicit tool, find one that matches
        my $cmap = $existing->{$new_task->checksum()};
        #search requested tools in order since that is preference order
        foreach my $req_tool(@{$new_task->requested_tools()}){
            if($cmap->{$req_tool}){
                ($need_new_task, $new_start_time) = $self->_evaluate_task($cmap->{$req_tool}, $need_new_task, $new_start_time);
            }
        }    
    }
    
    return $need_new_task, $new_start_time;
}

sub _evaluate_task {
    my ($self, $tmap, $need_new_task, $new_start_time) = @_;
    my $current_time = time;
    
    foreach my $uuid(keys %{$tmap}){
        my $old_task = $tmap->{$uuid};
        $old_task->{'keep'} = 1;
        my $until_ts = $self->_iso_to_ts($old_task->{task}->schedule_until());
        if($need_new_task){
            #if detail has start use that, otherwise use added time
            my $old_task_start_iso = ($old_task->{task}->detail_start() ? $old_task->{task}->detail_start() : $old_task->{task}->detail_added());
            my $old_task_start_ts = $self->_iso_to_ts($old_task_start_iso);
            if( (!$old_task->{task}->detail_exclusive()) && #not exclusive
                    $old_task->{task}->detail_multiresult() && #is multi-result
                    $old_task->{task}->detail_runs() == 1 && # just 1 run
                    ($old_task_start_ts + 15*60) < time # started at least 15 min ago
                ){
                #if background-multi, one or less runs and start time is 15 minutes (arbitrary) 
                # in the past the start time is immediately. Fixes special case where bgm 
                # task first run is not scheduled and thus no tests run
                $self->log_info("Stuck background-multi task found (start=$old_task_start_iso: $uuid, runs=1). Will cancel and recreate.");
                $old_task->{'keep'} = 0;
                $new_start_time = time;
            }elsif(!$until_ts || $until_ts > ($self->old_task_deadline() + ($self->new_task_min_ttl() * $self->task_renewal_fudge_factor()))){
                #if old task has no end time or will not expire before deadline, no task needed
                $need_new_task = 0 ;
                #continue with loop since need to mark other tasks that might be older as keep
            }elsif($until_ts > $current_time && (!$new_start_time || $new_start_time < $until_ts)){
                #if until_ts is in the future or found a task that runs longer then one we already saw, set the start time
                $new_start_time = $until_ts;
            }
        } 
    }
    
    return ($need_new_task, $new_start_time);
}

sub _create_tasks {
    my ($self) = @_;
    $self->logf()->global_context({"action" => "create"});
    
    # clear out previous added tasks
    $self->added_tasks([]); 
    
    $self->log_info("Creating tasks");
    $self->log_info("No tasks to create") unless(@{$self->new_tasks()});
    foreach my $new_task(@{$self->new_tasks()}){
        #determine lead - do here as optimization so we only do it for tests that need to be added
        $new_task->refresh_lead();
        if($new_task->error()){
            my $err = sprintf("Problem determining which pscheduler to submit test to for creation, skipping test %s: %s", $new_task->to_str, $new_task->error);
            $self->log_error($err);
            push @{$self->errors()}, $err;
            next;
        }
        $self->leads_to_keep()->{$new_task->url()} = 1;
        $self->log_task($new_task);
        $new_task->post_task();
        if($new_task->error){
            my $err = sprintf("Problem adding test %s, continuing with rest of config: %s", $new_task->to_str, $new_task->error);
            $self->log_error($err);
            push @{$self->errors()}, $err;
        }else{
            push @{$self->added_tasks()}, $new_task;
            $self->_update_lead($new_task->url(), { 'success_time' => time });
        } 
    }
    $self->log_info("Done creating tasks");

}

sub _write_tracker_file {
    my ($self) = @_;
    
    eval{
        my $content = {
            'leads' => $self->leads(),
            'archives' => $self->new_archives()
        };
        my $json = to_json($content, {"pretty" => 1});
        open( FOUT, ">", $self->tracker_file() ) or die "unable to open " . $self->tracker_file() . ": $@";
        print FOUT "$json";
        close( FOUT );
    };
    if($@){
        push @{$self->errors()}, $@;
    }
}

sub _cleanup_leads {
    my ($self) = @_;
    
    #clean out leads that we don't need anymore
    foreach my $lead_url(keys %{$self->leads()}){
        unless($self->leads_to_keep()->{$lead_url}){
            delete $self->leads()->{$lead_url};
        }
    }
}

sub _created_by {
    my $self = shift;
    my $client_uuid = $self->_get_client_uuid(file => $self->client_uuid_file());
    unless($client_uuid){
         $client_uuid = $self->_set_client_uuid(file =>  $self->client_uuid_file());
    }
    
    return {"uuid" => $client_uuid, "user-agent" => $self->user_agent()};
}

=head2 _get_client_uuid ({})
    Returns the UUID to use in the client-uuid field from a file
=cut
sub _get_client_uuid {
    my $self = shift;
    my $uuid;
    if ( open( FIN, "<", $self->client_uuid_file() ) ) {
        while($uuid = <FIN>){
            if ( $uuid ){
                 chomp( $uuid );
                 last;
            }
        }
        close( FIN );
    }

    return $uuid;
}

=head2 _set_client_uuid ({})
    Generates a UUID and stores in a file
=cut
sub _set_client_uuid {
    my $self = shift;
    my $uuid_file = $self->client_uuid_file();
    my $ug   = new Data::UUID;
    my $uuid = $ug->create_str();

    open( FOUT, ">", $uuid_file ) or die "unable to open $uuid_file: $@";
    print FOUT "$uuid";
    close( FOUT );
    
    return $uuid;
}

sub _read_json_file {
    my ($self, $json_file) = @_;
    
    my $json = {};
    #if file exists try to read it, otherwise, return empty json
    if( -e $json_file ){
        local $/; #enable perl to read an entire file at once
        open( my $json_fh, '<', $json_file ) or die("Unable to open task file $json_file: $@");
        my $json_text   = <$json_fh>;
        eval{ $json= decode_json( $json_text ) };
    }
        
    return $json;
}


sub _update_lead {
    my ($self, $url, $fields) = @_;
    
    $self->leads()->{$url} = {} unless($self->leads()->{$url});
    foreach my $field(keys %{$fields}){
        $self->leads()->{$url}->{$field} = $fields->{$field};
    }
}

sub _iso_to_ts {
     my ($self, $iso_str) = @_;
     
     #ignore if iso_str undefined
     return unless($iso_str);
     
     #parse 
     my $dt = DateTime::Format::ISO8601->parse_datetime( $iso_str );
     return $dt->epoch();
     
}

sub _ts_to_iso {
    my ($self, $ts) = @_;
    
    #ignore if iso_str undefined
    return unless($ts);
     
    my $date = DateTime->from_epoch(epoch => $ts, time_zone => 'UTC');
    return $date->ymd() . 'T' . $date->hms() . 'Z';
}

sub log_error {
    my ($self, $msg, $local_context) = @_;
    if($self->logger()){
        $self->logger()->error($self->logf()->format($msg, $local_context));
    }elsif($self->debug()){
        print "$msg\n";
    }
}

sub log_info {
    my ($self, $msg, $local_context) = @_;
    if($self->logger()){
        $self->logger()->info($self->logf()->format($msg, $local_context));
    }elsif($self->debug()){
        print "$msg\n";
    }
}

sub log_warn {
    my ($self, $msg, $local_context) = @_;
    if($self->logger()){
        $self->logger()->warn($self->logf()->format($msg, $local_context));
    }elsif($self->debug()){
        print "$msg\n";
    }
}

sub log_debug {
    my ($self, $msg, $local_context) = @_;
    if($self->logger()){
        $self->logger()->debug($self->logf()->format($msg, $local_context));
    }elsif($self->debug()){
        print "$msg\n";
    }
}

sub log_task {
    my ($self, $task) = @_;
    
    my $local_ctx = {};
    $local_ctx->{'checksum'} =  $task->checksum();
    $local_ctx->{'lead_url'} =  $task->url();
    $local_ctx->{'lead_bind'} =  $task->lead_bind() if($task->lead_bind());
    $local_ctx->{'test_type'} =  $task->test_type();
    
    if($self->logger()){
        $self->logger()->info($self->logf()->format_task($task, $local_ctx));
    }elsif($self->debug()){
        print $task->json({'pretty' => 1}) . "\n";
    }
}

__PACKAGE__->meta->make_immutable;

1;
