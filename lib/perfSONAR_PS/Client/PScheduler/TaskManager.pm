package perfSONAR_PS::Client::PScheduler::TaskManager;

=head1 NAME

perfSONAR_PS::Client::PScheduler::TaskManager - A client tracking and maintaining pScheduler tasks across multiple servers

=head1 DESCRIPTION

A client for interacting with pScheduler

=cut

use Mouse;
use Params::Validate qw(:all);
use JSON qw(from_json to_json decode_json);

use perfSONAR_PS::Client::PScheduler::ApiConnect;
use perfSONAR_PS::Client::PScheduler::ApiFilters;
use perfSONAR_PS::Client::PScheduler::Task;

use Data::Dumper;

our $VERSION = 4.0;

has 'pscheduler_url'      => (is => 'rw', isa => 'Str');
has 'task_file'           => (is => 'rw', isa => 'Str');
has 'client_uuid_file'    => (is => 'rw', isa => 'Str');
has 'user_agent'          => (is => 'rw', isa => 'Str');

has 'new_tasks'           => (is => 'rw', isa => 'ArrayRef[perfSONAR_PS::Client::PScheduler::Task]', default => sub{ [] });
has 'existing_task_map'   => (is => 'rw', isa => 'HashRef', default => sub{ {} });
has 'leads'               => (is => 'rw', isa => 'HashRef', default => sub{ {} });
has 'errors'              => (is => 'rw', isa => 'ArrayRef', default => sub{ [] });
has 'created_by'          => (is => 'rw', isa => 'HashRef', default => sub{ {} });
has 'leads_to_keep'       => (is => 'rw', isa => 'HashRef', default => sub{ {} });

sub init {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {
                                            pscheduler_url => 1,
                                            task_file => 1,
                                            client_uuid_file => 1,
                                            user_agent => 1
                                        } );
    #init this object
    $self->errors([]);
    $self->pscheduler_url($parameters->{'pscheduler_url'});
    $self->task_file($parameters->{'task_file'});
    $self->client_uuid_file($parameters->{'client_uuid_file'});
    $self->user_agent($parameters->{'user_agent'});
    $self->created_by($self->_created_by());
    
    #get list of leads
    my $task_file_json = $self->_read_json_file($self->task_file());
    my $psc_leads = $task_file_json->{'leads'} ? $task_file_json->{'leads'} : {};
    $self->leads($psc_leads);
    $self->_update_lead($self->pscheduler_url(), {}); #init local url
    
    #build list of existing tasks
    foreach my $psc_url(keys %{$self->leads()}){
        #Query lead
        my $psc_lead = $self->leads()->{$psc_url};
        my $existing_task_map = {};
        my $psc_filters = new perfSONAR_PS::Client::PScheduler::ApiFilters();
        #todo: need status filter?
        $psc_filters->reference_param("created-by", $self->created_by());
        my $psc_client = new perfSONAR_PS::Client::PScheduler::ApiConnect(url => $psc_url, filters => $psc_filters);
        my $existing_tasks = $psc_client->get_tasks();
        if($psc_client->error()){
            $psc_lead->{'error_time'} = time; 
            push @{$self->errors()}, "Problem getting existing tests from pScheduler lead $psc_url: ".$psc_client->error();
            next;
        }
        #Add to existing task map
        foreach my $existing_task(@{$existing_tasks}){
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
    my $parameters = validate( @args, {task => 1, local_address => 0 } );
    my $new_task = $parameters->{task};
    my $local_address = $parameters->{local_address};
    
    $new_task->reference_param('created-by', $self->created_by());
    $new_task->reference_param('created-by')->{'address'} = $local_address if($local_address);
    if(!$self->_task_exists($new_task)){
        #task does not exist, we need to create it
        push @{$self->new_tasks()}, $new_task;
    }

}

sub commit {
    my ($self) = @_;
    
    $self->errors([]);
    
    $self->_delete_tasks();
    $self->_create_tasks();
    $self->_cleanup_leads();
    $self->_write_task_file();
}

sub _delete_tasks {
    my ($self) = @_;
    print "-----------------------------------\n";
    print "DELETING TASKS\n";
    print "-----------------------------------\n";
    foreach my $checksum(keys %{$self->existing_task_map()}){
        my $cmap = $self->existing_task_map()->{$checksum};
        foreach my $tool(keys %{$cmap}){
            my $tmap = $cmap->{$tool};
            foreach my $uuid(keys %{$tmap}){
                #prep task
                my $meta_task = $tmap->{$uuid};
                my $task = $meta_task->{'task'};
                $task->refresh_lead();
                if($task->error){
                    push @{$self->errors()}, "Problem determining which pscheduler to submit test to for deletion, skipping test: " . $task->error;
                    next;
                }
                
                #if we keep, make sure we track lead, otherwise delete
                if($meta_task->{'keep'}){
                    #make sure we keep the lead around
                    $self->leads_to_keep()->{$task->url()} = 1;
                }else{
                    $self->_print_task($task);
                    # TODO:uncomment
                    # $task->delete_task();
                    # if($task->error()){
                    #     $self->leads_to_keep()->{$task->url()} = 1;
                    #     $self->_update_lead($task->url(), {'error_time' => time});
                    #     push @{$self->errors()}, "Problem deleting test, continuing with rest of config: " . $task->error();
                    # }                    
                }
            }
        }
    }
}

sub _task_exists {
    my ($self, $new_task) = @_;
    
    my $existing = $self->existing_task_map();
    
    #if no matching checksum, then does not exist
    if(!$existing->{$new_task->checksum()}){
        return 0;
    }
    
    #if matching checksum, and tool is not defined on new task then we match
    if(!$new_task->requested_tools()){
        my $cmap = $existing->{$new_task->checksum()};
        foreach my $tool(keys %{$cmap}){
            my $tmap = $cmap->{$tool};
            foreach my $uuid(keys %{$tmap}){
                #mark as keep
                 $tmap->{$uuid}->{'keep'} = 1;
                #only mark the first one you see so we don't keep duplicate tests
                return 1;
            }
        }
    }
    
    #we have a matching checksum and we have an explicit tool, find one that matches
    my $cmap = $existing->{$new_task->checksum()};
    #search requested tools in order since that is preference order
    foreach my $req_tool(@{$new_task->requested_tools()}){
        if($cmap->{$req_tool}){
            my $tmap = $cmap->{$req_tool};
            foreach my $uuid(keys %{$tmap}){
                #mark as keep
                $tmap->{$uuid}->{'keep'} = 1;
                #only mark the first one you see so we don't keep duplicate tests
                return 1;
            }
        }
    }    
    #if we are here, no match
    return 0;
}

sub _create_tasks {
    my ($self) = @_;
    
    print "+++++++++++++++++++++++++++++++++++\n";
    print "ADDING TASKS\n";
    print "+++++++++++++++++++++++++++++++++++\n";
    foreach my $new_task(@{$self->new_tasks()}){
        #determine lead - do here as optimization so we only do it for tests that need to be added
        $new_task->refresh_lead();
        if($new_task->error()){
            push @{$self->errors()}, "Problem determining which pscheduler to submit test to for creation, skipping test: " . $new_task->error();
            next;
        }
        $self->leads_to_keep()->{$new_task->url()} = 1;
        $self->_print_task($new_task);
        $new_task->post_task();
        if($new_task->error){
            push @{$self->errors()}, "Problem adding test, continuing with rest of config: " . $new_task->error;
        }
        $self->_update_lead($new_task->url(), { 'success_time' => time });
    }

}

sub _write_task_file {
    my ($self) = @_;
    
    eval{
        my $content = {
            'leads' => $self->leads()
        };
        my $json = to_json($content, {"pretty" => 1});
        open( FOUT, ">", $self->task_file() ) or die "unable to open " . $self->task_file() . ": $@";
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
        $json= decode_json( $json_text )
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

#Useful for debugging
sub _print_task {
    my ($self, $task) = @_;
    
    print "Test Type: " . $task->test_type() . "\n";
    print "Tool: " . ($task->tool() ? $task->tool() : 'n/a') . "\n";
    print "Source: " . $task->test_spec_param("source") . "\n";
    print "Destination: " . ($task->test_spec_param("dest") ?  $task->test_spec_param("dest") : $task->test_spec_param("destination")). "\n";
    print "Lead URL: " . $task->url() . "\n";
    print "Checksum: " . $task->checksum() . "\n";
    print "Created By:\n";
    my $created_by = $task->reference_param('created-by');
    foreach my $cp(keys %{$created_by}){
         print "    $cp: " . $created_by->{$cp} . "\n";
    }
    print "Test Spec:\n";
    foreach my $tp(keys %{$task->test_spec}){
         print "    $tp: " . $task->test_spec_param($tp) . "\n";
    }
    if($task->schedule()){
        print "Schedule:\n";
        print "    repeat: " . $task->schedule_repeat() . "\n" if(defined $task->schedule_repeat());
        print "    max runs: " . $task->schedule_maxruns() . "\n" if(defined $task->schedule_maxruns());
        print "    slip: " . $task->schedule_slip() . "\n" if(defined $task->schedule_slip());
        print "    randslip: " . $task->schedule_randslip() . "\n" if(defined $task->schedule_randslip());
        print "    start: " . $task->schedule_start() . "\n" if(defined $task->schedule_start());
        print "    until: " . $task->schedule_until() . "\n" if(defined $task->schedule_until());
    }
    print "Archivers:\n";
    foreach my $a(@{$task->archives()}){
        print "    name: " . $a->name() . "\n";
        print "    url: " . $a->data()->{'url'} . "\n";
    }
    print "\n";
}

__PACKAGE__->meta->make_immutable;

1;