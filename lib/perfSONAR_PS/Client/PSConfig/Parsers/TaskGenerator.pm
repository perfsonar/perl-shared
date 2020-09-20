package perfSONAR_PS::Client::PSConfig::Parsers::TaskGenerator;

=head1 NAME

perfSONAR_PS::Client::PSConfig::Parsers::TaskGenerator - A library for generating a list of tasks represented by a PSConfig

=head1 DESCRIPTION

A library for generating a list of tasks represented by a PSConfig. Iterates through
each task in a Config object and organizes into a list of tasks.

=cut

use Mouse;
use Params::Validate qw(:all);
use Log::Log4perl qw(get_logger);

use perfSONAR_PS::Client::PSConfig::Config;
use perfSONAR_PS::Client::PSConfig::Parsers::Template;
use perfSONAR_PS::Client::PScheduler::Task;
use perfSONAR_PS::Client::PScheduler::ApiConnect;

use JSON qw(encode_json);

our $VERSION = 4.1;

my $logger;
if(Log::Log4perl->initialized()) {
    #this is intended to be a lib reliant on someone else initializing env
    #detect if they did but quietly move on if not
    #anything using $logger will need to check if defined
    $logger = get_logger(__PACKAGE__);
}


has 'task_name' => (is => 'rw', isa => 'Str');
has 'psconfig' => (is => 'rw', isa => 'perfSONAR_PS::Client::PSConfig::Config', default => sub { new perfSONAR_PS::Client::PSConfig::Config(); });
has 'match_addresses' => (is => 'rw', isa => 'ArrayRef[Str]', default => sub {[]});
has 'pscheduler_url' => (is => 'rw', isa => 'Str');
has 'default_archives' => (is => 'rw', isa => 'ArrayRef[perfSONAR_PS::Client::PSConfig::Archive]', default => sub { [] });
has 'use_psconfig_archives' => (is => 'rw', isa => 'Bool', default => sub { 1 });
has 'bind_map' => (is => 'rw', isa => 'HashRef', default => sub { {} });

#read-only
##Updated whenever an error occurs
has 'error' => (is => 'ro', isa => 'Str|Undef', writer => '_set_error');
##Updated on call to start()
has 'started' => (is => 'ro', isa => 'Bool', writer => '_set_started');
has 'task' => (is => 'ro', isa => 'perfSONAR_PS::Client::PSConfig::Task|Undef', writer => '_set_task');
has 'group' => (is => 'ro', isa => 'perfSONAR_PS::Client::PSConfig::Groups::BaseGroup|Undef', writer => '_set_group');
has 'schedule' => (is => 'ro', isa => 'perfSONAR_PS::Client::PSConfig::Schedule|Undef', writer => '_set_schedule');
has 'tools' => (is => 'ro', isa => 'ArrayRef[Str]|Undef', writer => '_set_tools');
has 'priority' => (is => 'ro', isa => 'Int', writer => '_set_priority');
has 'test' => (is => 'ro', isa => 'perfSONAR_PS::Client::PSConfig::Test|Undef', writer => '_set_test');
##Updated each call to next()
has 'expanded_test' => (is => 'ro', isa => 'HashRef|Undef', writer => '_set_expanded_test');
has 'expanded_archives' => (is => 'ro', isa => 'ArrayRef|Undef', writer => '_set_expanded_archives');
has 'expanded_contexts' => (is => 'ro', isa => 'ArrayRef|Undef', writer => '_set_expanded_contexts');
has 'expanded_reference' => (is => 'ro', isa => 'HashRef|Undef', writer => '_set_expanded_reference');
has 'scheduled_by_address' => (is => 'ro', isa => 'perfSONAR_PS::Client::PSConfig::Addresses::BaseAddress|Undef', writer => '_set_scheduled_by_address');
has 'addresses' => (is => 'ro', isa => 'ArrayRef[perfSONAR_PS::Client::PSConfig::Addresses::BaseAddress]|Undef', writer => '_set_addresses');

#private
has '_match_addresses_map' => (is => 'ro', isa => 'HashRef|Undef', writer => '_set_match_addresses_map');

=item start()

Prepares generator to begin iterating through tasks. Must be run before any call to next()

=cut

sub start {
    my ($self) = @_;
    
    #handle required properties without defaults
    unless($self->task_name()){
        $self->_set_error("TaskGenerator must be given a task_name property");
        return;
    }
    
    #find task
    my $task = $self->psconfig()->task($self->task_name());
    if($task){
        $self->_set_task($task);
    }else{
        $self->_set_error("Unable to find a task with name " . $self->task_name());
        return;
    }
    
    #find group
    my $group = $self->psconfig()->group($task->group_ref());
    if($group){
        $self->_set_group($group);
    }else{
        $self->_set_error("Unable to find a group with name " . $task->group_ref());
        return;
    }
    
    #find test
    my $test = $self->psconfig()->test($task->test_ref());
    if($test){
        $self->_set_test($test);
    }else{
        $self->_set_error("Unable to find a test with name " . $task->test_ref());
        return;
    }
    
    #find schedule (optional)
    my $schedule = $self->psconfig()->schedule($task->schedule_ref());
    if($schedule){
        $self->_set_schedule($schedule);
    }
    
    #find tools (optional)
    my $tools = $task->tools();
    if($tools && @{$tools}){
        $self->_set_tools($tools);
    }
    
    #find priority (optional)
    my $priority = $task->priority();
    if(defined $priority){
        $self->_set_priority($priority);
    }
    
    #set match addresses if any
    if(@{$self->match_addresses()} > 0){
        my %match_addresses_map = map { lc($_) => 1 } @{$self->match_addresses()};
        $self->_set_match_addresses_map(\%match_addresses_map);
    }else{
        $self->_set_match_addresses_map(undef);
    }
    
    #validate specs?
    
    #start group
    $group->start($self->psconfig());
    
    #set started
    $self->_set_started(1);
    
    #return true if reach here
    return 1;
    
}

=item next()

Finds the next matching task. Returns the addresses and remaining values can be pulled
from class properties

=cut

sub next {
    my ($self) = @_;
    
    #make sure we are started
    unless($self->started()){
        return;
    }
    
    #clear out stuff set each next iteration
    $self->_reset_next();
    
    #find the next test we have to run
    my $scheduled_by = $self->task()->scheduled_by() ?  $self->task()->scheduled_by() : 0;
    my @addrs;
    my $matched = 0;
    my $flip = 0;
    my $scheduled_by_addr;
    while(@addrs = $self->group()->next()){
        #validate scheduled by
        if($scheduled_by >= @addrs){
            $self->_set_error("The scheduled-by property for task  " . $self->task_name() . " is too big. It is set to $scheduled_by but must not be bigger than " . @addrs);
            return;
        }
        
        #check if disabled
        my $disabled = 0;
        foreach my $addr(@addrs){
            if($self->_is_disabled($addr)){
                $disabled = 1;
                last;
            }
        }
        next if($disabled);
        
        #get the scheduled-by address
        $scheduled_by_addr = $addrs[$scheduled_by];
        #if the default scheduled-by address is no-agent, pick first address that is not no-agent
        my $has_agent = 0;
        my $needs_flip = 0; #local var so don't leak non-matching address flip value to matching address
        if($self->_is_no_agent($scheduled_by_addr)){
            $needs_flip = 1;
            foreach my $addr(@addrs){
                if(!$self->_is_no_agent($addr)){
                    $scheduled_by_addr = $addr;
                    $has_agent = 1;
                    last;
                }
            }
        }else{
            $has_agent = 1;
        }
        
        #if the address responsible for scheduling matches us, exit loop, otherwise keep looking
        if($has_agent && $self->_is_matching_address($scheduled_by_addr)){
            $matched = 1;
            $flip = $needs_flip;
            last;
        }  
    }
    
    #if no match, then exit
    unless($matched){
        return;
    }
    
    #set addresses
    $self->_set_addresses(\@addrs);
    
    ##
    #create object to be queried by jq template vars
    my $archives = $self->_get_archives($scheduled_by_addr);
    if($self->error()){
         return $self->_handle_next_error(\@addrs, $self->error());
    }
    my $hosts = $self->_get_hosts();
    if($self->error()){
         return $self->_handle_next_error(\@addrs, $self->error());
    }
    my $contexts = [];
    foreach my $addr(@addrs){
        my $addr_contexts = $self->_get_contexts($addr);
        if($self->error()){
            return $self->_handle_next_error(\@addrs, $self->error());
        }
        push @{$contexts}, $addr_contexts;
    }
    my $jq_obj = $self->_jq_obj($archives, $hosts, $contexts);
    ## end jq obj
    
    #init template so we can start explanding variables
    my $template = new perfSONAR_PS::Client::PSConfig::Parsers::Template(
        groups => \@addrs,
        scheduled_by_address => $scheduled_by_addr,
        flip => $flip,
        jq_obj => $jq_obj
    );
    
    #set scheduled_by_address for this iteration
    $self->_set_scheduled_by_address($scheduled_by_addr);
    
    #expand test spec
    my $test = $template->expand($self->test()->data());
    if($test){
        $self->_set_expanded_test($test);
    }else{
        return $self->_handle_next_error(\@addrs, "Error expanding test specification: " . $template->error());
    }

    #expand archivers
    my $expanded_archives = [];
    foreach my $archive(@{$archives}){
        my $expanded_archive = $template->expand($archive);
        unless($expanded_archive){
            return $self->_handle_next_error(\@addrs, "Error expanding archives: " . $template->error());
        }
        push @{$expanded_archives}, $expanded_archive;
    }
    $self->_set_expanded_archives($expanded_archives);

    #expand contexts
    #Note: Assumes first address is first participant, second is second participant, etc.
    my $expanded_contexts = [];
    foreach my $context(@{$contexts}){
        # query https://pscheduler_server/pscheduler/tests/<test_name>/participants?spec={...}
        # e. g. https://147.91.1.235/pscheduler/tests/rtt/participants?spec=%7B%22source-node%22:%22147.91.1.235%22,%22dest%22:%22147.91.27.4%22,%22source%22:%22147.91.1.235%22,%22ip-version%22:4,%22ttl%22:255,%22schema%22:1%7D
        # analyze reply
        # e.g. {"participants": ["147.91.1.235"]}
        # expand contexts only for multiparticipant tests

        my $test_data = $self->test()->data();
        my $test_data_spec = $self->test()->data()->{'spec'};
        my %test_data_hash = ();
        my %test_data_spec_hash = ();
        foreach my $test_data_key (keys %$test_data_spec) {
        my $test_data_value = $test_data_spec->{$test_data_key};
            $test_data_spec_hash{ $test_data_key } = $test_data_value;
            # expand address
            foreach my $address_index (0 .. @addrs) {
                my $address_value = ($addrs[$address_index]) ? $addrs[$address_index]->address() : $test_data_value;
                my $expanded_value = $test_data_value;
                if ($expanded_value =~ /\{\% address\[$address_index\] \%\}/) {
                    $expanded_value =~ s/\{\% address\[$address_index\] \%\}/$address_value/;
                    $test_data_spec_hash{ $test_data_key } = $expanded_value;
                }
            }

        }

        $test_data_hash{'type'} = $test_data->{'type'};
        $test_data_hash{'spec'} = \%test_data_spec_hash;

        my $test_data_json = encode_json \%test_data_hash;
        # remove quotes around numbers
        # I did't find more elegant way for unquoting numbers
        $test_data_json =~ s/\"([0-9]+)\"/$1/g;
#        my $test_data_json = "{\"type\":\"rtt\",\"spec\":{\"source-node\":\"147.91.1.235\",\"dest\":\"147.91.27.4\",\"source\":\"147.91.1.235\",\"ip-version\":4,\"ttl\":255,\"schema\":1}}";

        #!!! hardcoded pscheduler_address and scheme in psc_url
        # my $psc_url = "https://147.91.1.235/pscheduler/tests";
        my $psc_url = $self->pscheduler_url() . "/pscheduler/tests";
        my $psc_client = new perfSONAR_PS::Client::PScheduler::ApiConnect(url => $psc_url);
        my $is_multiparticipant_test = $psc_client->get_test_is_multiparticipant($test_data_json); # "{\"type\":\"rtt\",\"spec\":{\"source-node\":\"147.91.1.235\",\"dest\":\"147.91.27.4\",\"source\":\"147.91.1.235\",\"ip-version\":4,\"ttl\":255,\"schema\":1}}");
        if ($is_multiparticipant_test) {
            my $expanded_context = $template->expand($context);
            unless($expanded_context){
                return $self->_handle_next_error(\@addrs, "Error expanding context: " . $template->error());
            }
            push @{$expanded_contexts}, $expanded_context;
        }
    }
    $self->_set_expanded_contexts($expanded_contexts);
    
    #expand reference
    my $reference;
    if($self->task()->reference()){
        $reference = $template->expand($self->task()->reference());
        if($reference){
            $self->_set_expanded_reference($reference);
        }else{
            return $self->_handle_next_error(\@addrs, "Error expanding reference: " . $template->error());
        }
    }

    #return the matching address set
    return @addrs;
}


=item stop()

Stops the iteration and resets variables

=cut

sub stop {
    my ($self) = @_;
    
    $self->_reset_next();
    $self->_set_started(0);
    $self->group()->stop();
    $self->_set_task(undef);
    $self->_set_group(undef);
    $self->_set_schedule(undef);
}

=item pscheduler_task()

Converts current task to a pScheduler Task object

=cut

sub pscheduler_task {
    my ($self) = @_;
    
    #make sure we are started
    unless($self->started()){
        return;
    }
    
    #create hash to be used as data
    my $task_data = {};
    
    #set test
    if($self->expanded_test()){
        $task_data->{"test"} = $self->_pscheduler_prep($self->expanded_test());
    }else{
        $self->_set_error("No expanded test found, can't create ");
        return;
    }
    
    #set archives
    if($self->expanded_archives()){
        foreach my $archive(@{$self->expanded_archives()}){
            $self->_pscheduler_prep($archive);
        }
        $task_data->{"archives"} = $self->expanded_archives();
    }
    
    #set contexts
    if($self->expanded_contexts()){
        my $has_context = 0;
        foreach my $participant(@{$self->expanded_contexts()}){
            foreach my $context(@{$participant}){
                $self->_pscheduler_prep($context);
                $has_context = 1;
            }
        }
        if($has_context){
            $task_data->{"contexts"} = {
                'contexts' => $self->expanded_contexts()
            };
        }
    }
    
    #set schedule
    if($self->schedule()){
        $task_data->{"schedule"} = $self->_pscheduler_prep($self->schedule()->data());
    }
    
    #set reference
    if($self->expanded_reference()){
        $task_data->{"reference"} = $self->expanded_reference();
    }
    
    #set tools
    if($self->tools()){
        $task_data->{"tools"} = $self->tools();
    }
    
    #set priority
    if(defined $self->priority()){
        $task_data->{"priority"} = $self->priority();
    }
    
    #time to create pscheduler task
    my $psched_task = new perfSONAR_PS::Client::PScheduler::Task(
        url => $self->pscheduler_url(),
        data => $task_data
    );
    
    #set bind map - defaults to empty object
    $psched_task->bind_map($self->bind_map());
        
    #set lead bind address
    foreach my $addr(@{$self->addresses()}){
        if($addr->lead_bind_address()){
            $psched_task->add_lead_bind_map($addr->address(), $addr->lead_bind_address());
            #since pscheduler may return pscheduler-address as lead, also need that in map if defined
            $psched_task->add_lead_bind_map($addr->pscheduler_address(), $addr->lead_bind_address()) if($addr->pscheduler_address());
        }
    }    
    
    return $psched_task;
}

sub _jq_obj{
    my ($self, $archives, $hosts, $contexts) = @_;
    
    #convert addresses
    my $addresses = [];
    foreach my $address(@{$self->addresses()}){
        push @{$addresses}, $address->data();
    }
    
    #return object
    my $jq_obj = {
        "addresses" => $addresses,
        "archives" => $archives,
        "contexts" => $contexts,
        "hosts" => $hosts,
        "task" => $self->task()->data(),
        "test" => $self->test()->data()
    };
    $jq_obj->{"schedule"} = $self->schedule()->data() if($self->schedule());
    
    return $jq_obj;
}

sub _pscheduler_prep{
    my ($self, $obj) = @_;
    
    #this is a pass by reference, so _meta will be gone in any uses after this
    #if this becomes a problem we can copy, but for efficiency purposes just removing for now
    if(exists $obj->{'_meta'}){
        delete $obj->{'_meta'};
    }
    return $obj;
}

sub _is_matching_address{
    my ($self, $address) = @_;
    
    #if undefined matching addresses then everything matches 
    unless(defined $self->_match_addresses_map()){
        return 1;
    }
    
    
    if($address->_parent_address()){
        #if parent is set, then must match parent, otherwise no match
        if($self->_match_addresses_map()->{lc($address->_parent_address())}){
            return 1;
        }
    }elsif($self->_match_addresses_map()->{lc($address->address())}){
        #no parent set, so match address
        return 1;
    }
    
    #if get here , then not a match
    return 0;
}

sub _is_no_agent{
    ##
    # Checks if address or host has no-agent set. If either has it set then it 
    # will be no-agent.
    my ($self, $address) = @_;
    
    #return undefined if no address given
    unless($address){
        return;
    }
    
    #check address no_agent
    if($address->_is_no_agent()){
        return 1;
    }
    
    #check host no_agent
    my $host;
    if($address->can('host_ref') && $address->host_ref()){
        $host = $self->psconfig()->host($address->host_ref());
    }elsif($address->_parent_host_ref()){
        $host = $self->psconfig()->host($address->_parent_host_ref());
    }
    
    if($host && $host->no_agent()){
        return 1;
    }
    
    return 0;
}

sub _is_disabled{
    ##
    # Checks if address or host has disabled set. If either has it set then it 
    # will be disabled.
    my ($self, $address) = @_;
    
    #return undefined if no address given
    unless($address){
        return;
    }
    
    #check address disabled
    if($address->_is_disabled()){
        return 1;
    }
    
    #check host disabled
    my $host;
    if($address->can('host_ref') && $address->host_ref()){
        $host = $self->psconfig()->host($address->host_ref());
    }elsif($address->_parent_host_ref()){
        $host = $self->psconfig()->host($address->_parent_host_ref());
    }
    
    if($host && $host->disabled()){
        return 1;
    }
    
    return 0;
}

sub _get_archives{
    my ($self, $address, $template) = @_;
    
    my @archives = ();
    unless($address){
        return \@archives;
    }
    
    #init some values
    my $task = $self->task();
    my $psconfig = $self->psconfig();
    my %archive_tracker = ();
    
    #configuring archives from psconfig if allowed
    if($self->use_psconfig_archives()){
        my $host;
        if($address->can('host_ref') && $address->host_ref()){
            $host = $self->psconfig()->host($address->host_ref());
        }elsif($address->_parent_host_ref()){
            $host = $self->psconfig()->host($address->_parent_host_ref());
        }
        my @archive_refs = ();
        push @archive_refs, @{$task->archive_refs()} if($task->archive_refs());
        push @archive_refs, @{$host->archive_refs()} if($host && $host->archive_refs());
        #iterate through archives skipping duplicates
        foreach my $archive_ref(@archive_refs){
            #get archive obj
            my $archive = $psconfig->archive($archive_ref);
            unless($archive){
                $self->_set_error("Unable to find archive defined in task: $archive_ref");
                return;
            }
            #check if duplicate
            my $checksum = $archive->checksum();
            next if($archive_tracker{$checksum}); #skip duplicates
            #if made it here, add to the list
            $archive_tracker{$checksum} = 1;
            push @archives, $archive->data();
        }
    }
    
    #configure default archives
    foreach my $archive(@{$self->default_archives()}){
        #check if duplicate
        my $checksum = $archive->checksum();
        next if($archive_tracker{$checksum}); #skip duplicates
        #if made it here, add to the list
        $archive_tracker{$checksum} = 1;
        push @archives, $archive->data();
    }
    
    return \@archives;
    
}

sub _get_hosts{
    ##
    # Get hosts for each address.
    my ($self) = @_;
    
    #iterate addresses
    my $hosts = [];
    foreach my $address(@{$self->addresses()}){
        #check host no_agent
        my $host;
        if($address->can('host_ref') && $address->host_ref()){
            $host = $self->psconfig()->host($address->host_ref());
        }elsif($address->_parent_host_ref()){
            $host = $self->psconfig()->host($address->_parent_host_ref());
        }
        if($host){
            push @{$hosts}, $host->data();
        }else{
            push @{$hosts}, {}; #push empty object to keep indices consistent
        }
    }
        
    return $hosts;
}

sub _get_contexts{
    my ($self, $address) = @_;
    
    my @contexts = ();
    unless($address && $address->context_refs()){
        return \@contexts;
    }
    
    #init some values
    my $psconfig = $self->psconfig();
    foreach my $context_ref(@{$address->context_refs()}){
        my $context = $psconfig->context($context_ref);
        unless($context){
            $self->_set_error("Unable to find context '$context_ref' defined for address ". $address->address());
            return;
        }
        push @contexts, $context->data();
    }
    
    return \@contexts;
}

sub _handle_next_error {
    my ($self, $addrs, $error) = @_;
    
    my $addr_string = "";
    foreach my $addr(@{$addrs}){
        $addr_string .= '->' if($addr_string);
        if($addr && $addr->address()){
            $addr_string .= $addr->address();
        }else{
            $addr_string .= "undefined";
        }   
    }
    $error = "Unspecified" unless($error);
    
    $self->_set_error("task=" . $self->task_name . ",addresses=" . $addr_string . ",error=" . $error);
    
    return @{$addrs};
}

sub _reset_next {
    my ($self) = @_;
    
    $self->_set_error(undef);
    $self->_set_expanded_test(undef);
    $self->_set_expanded_archives(undef);
    $self->_set_expanded_contexts(undef);
    $self->_set_expanded_reference(undef);
    $self->_set_scheduled_by_address(undef);
    $self->_set_addresses(undef);
}
 

__PACKAGE__->meta->make_immutable;

1;
