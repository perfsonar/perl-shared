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

#private
has 'started' => (is => 'ro', isa => 'Bool', writer => '_set_started');
has 'error' => (is => 'ro', isa => 'Str', writer => '_set_error');
has 'task' => (is => 'ro', isa => 'perfSONAR_PS::Client::PSConfig::Task|Undef', writer => '_set_task');
has 'group' => (is => 'ro', isa => 'perfSONAR_PS::Client::PSConfig::Groups::BaseGroup|Undef', writer => '_set_group');
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
    
    #set match addresses if any
    if(@{$self->match_addresses()} > 0){
        my %match_addresses_map = map { $_ => 1 } @{$self->match_addresses()};
        $self->_set_match_addresses_map(\%match_addresses_map);
    }else{
        $self->_set_match_addresses_map(undef);
    }
    
    #validate specs?
    
    #iterate through hosts
    
    
    #start group
    $group->start($self->psconfig());
    
    #set started
    $self->_set_started(1);
    
    #return true if reach here
    return 1;
    
}

sub is_matching_address{
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

sub is_no_agent{
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

sub is_disabled{
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

sub next {
    my ($self) = @_;
    
    #find the next test we have to run
    my $scheduled_by = $self->task()->scheduled_by() ?  ($self->task()->scheduled_by() - 1) : 0;
    my @addrs;
    use Data::Dumper;
    
    my $matched = 0;
    while(@addrs = $self->group()->next()){
        #validate scheduled by
        if($scheduled_by >= @addrs){
            $self->_set_error("The scheduled-by property for task  " . $self->task_name() . " is too big. It is set to $scheduled_by but must not be bigger than " . @addrs);
            return;
        }
        
        #check if disabled
        my $disabled = 0;
        foreach my $addr(@addrs){
            if($self->is_disabled($addr)){
                $disabled = 1;
                last;
            }
        }
        next if($disabled);
        
        #get the scheduled-by address
        my $scheduled_by_addr = $addrs[$scheduled_by];
        #if the default scheduled-by address is no-agent, pick first address that is not no-agent
        my $has_agent = 0;
        if($self->is_no_agent($scheduled_by_addr)){
            foreach my $addr(@addrs){
                if(!$self->is_no_agent($addr)){
                    $scheduled_by_addr = $addr;
                    $has_agent = 1;
                    last;
                }
            }
        }else{
            $has_agent = 1;
        }
        
        #if the address responsible for scheduling matches us, exit loop, otherwise keep looking
        if($has_agent && $self->is_matching_address($scheduled_by_addr->address())){
            $matched = 1;
            last;
        }  
    }
    
    #todo: the will return an entire filled-in task, this is just for testing
    if($matched){
        return @addrs;
    }
    
    return;
}

sub stop {
    my ($self) = @_;
    
    $self->_set_started(0);
    $self->group()->stop();
    $self->_set_task(undef);
    $self->_set_group(undef);
}


 

__PACKAGE__->meta->make_immutable;

1;