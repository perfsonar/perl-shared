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

#read-only
##Updated whenever an error occurs
has 'error' => (is => 'ro', isa => 'Str|Undef', writer => '_set_error');
##Updated on call to start()
has 'started' => (is => 'ro', isa => 'Bool', writer => '_set_started');
has 'task' => (is => 'ro', isa => 'perfSONAR_PS::Client::PSConfig::Task|Undef', writer => '_set_task');
has 'group' => (is => 'ro', isa => 'perfSONAR_PS::Client::PSConfig::Groups::BaseGroup|Undef', writer => '_set_group');
has 'schedule' => (is => 'ro', isa => 'perfSONAR_PS::Client::PSConfig::Schedule|Undef', writer => '_set_schedule');
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

sub start {
    my ($self) = @_;
    
    #handle required properties
    unless($self->psconfig()){
        $self->_set_error("TaskGenerator must be given a psconfig property");
        return;
    }
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
    
    #set match addresses if any
    if(@{$self->match_addresses()} > 0){
        my %match_addresses_map = map { $_ => 1 } @{$self->match_addresses()};
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

sub next {
    my ($self) = @_;
    
    #make sure we are started
    unless($self->started()){
        return;
    }
    
    #clear out stuff set each next iteration
    $self->_reset_next();
    
    #find the next test we have to run
    my $scheduled_by = $self->task()->scheduled_by() ?  ($self->task()->scheduled_by() - 1) : 0;
    my @addrs;
    my $matched = 0;
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
        if($self->_is_no_agent($scheduled_by_addr)){
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
        if($has_agent && $self->_is_matching_address($scheduled_by_addr->address())){
            $matched = 1;
            last;
        }  
    }
    
    #if no match, then exit
    unless($matched){
        return;
    }
    
    #set addresses
    $self->_set_addresses(\@addrs);
    
    #init template so we can start explanding variables
    my $template = new perfSONAR_PS::Client::PSConfig::Parsers::Template(
        groups => \@addrs,
        scheduled_by_address => $scheduled_by_addr
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
    my $archives = $self->_get_archives($scheduled_by_addr, $template);
    if($archives){
        $self->_set_expanded_archives($archives);
    }else{
        return $self->_handle_next_error(\@addrs, "Error expanding archives: " . $self->error());
    }
    
    #expand contexts
    #Note: Assumes first address is first participant, second is second participant, etc.
    my $contexts = [];
    foreach my $addr(@addrs){
        my $addr_contexts = $self->_get_contexts($addr, $template);
        if($addr_contexts){
            push @{$contexts}, $addr_contexts;
        }else{
            return $self->_handle_next_error(\@addrs, "Error expanding contexts: " . $self->error());
        }
    }
    $self->_set_expanded_contexts($contexts);
    
    #expand reference
    my $reference;
    if($self->task()->reference()){
        $reference = $template->expand($self->task()->reference()->data());
        if($reference){
            $self->_set_expanded_reference($reference);
        }else{
            return $self->_handle_next_error(\@addrs, "Error expanding reference: " . $self->error());
        }
    }
    
    #return the matching address set
    return @addrs;
}

sub stop {
    my ($self) = @_;
    
    $self->_reset_next();
    $self->_set_started(0);
    $self->group()->stop();
    $self->_set_task(undef);
    $self->_set_group(undef);
    $self->_set_schedule(undef);
}

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
        $task_data->{"contexts"} = $self->expanded_contexts() if($has_context);
    }
    
    #set schedule
    if($self->schedule()){
        $task_data->{"schedule"} = $self->_pscheduler_prep($self->schedule()->data());
    }
    
    #set reference
    if($self->expanded_reference()){
        $task_data->{"reference"} = $self->expanded_reference();
    }
    
    #time to create pscheduler task
    my $psched_task = new perfSONAR_PS::Client::PScheduler::Task(
        url => $self->pscheduler_url(),
        data => $task_data
    );
    
    #set bind address
    if($self->scheduled_by_address()->agent_bind_address()){
        $psched_task->add_local_bind_map($self->scheduled_by_address()->agent_bind_address());
    }
    
    #set lead bind address and pscheduler address
    foreach my $addr(@{$self->addresses()}){
        if($addr->lead_bind_address()){
            $psched_task->add_lead_bind_map($addr->address(), $addr->lead_bind_address());
        }
        if($addr->pscheduler_address()){
            $psched_task->add_pscheduler_address($addr->address(), $addr->pscheduler_address());
        }
    }    
    
    return $psched_task;
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
    
    #if in map then matches
    if($self->_match_addresses_map()->{$address}){
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
        #expand template vars
        my $expanded = $template->expand($archive->data());
        unless($expanded){
            self->_set_error("Error expanding archive template variables: " . $template->error());
            return;
        }
        #if made it here, add to the list
        $archive_tracker{$checksum} = 1;
        push @archives, $expanded;
    }
    
    return \@archives;
    
}

sub _get_contexts{
    my ($self, $address, $template) = @_;
    
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
        my $expanded = $template->expand($context->data());
        unless($expanded){
            self->_set_error("Error expanding context template variables: " . $template->error());
            return;
        }
        push @contexts, $expanded;
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