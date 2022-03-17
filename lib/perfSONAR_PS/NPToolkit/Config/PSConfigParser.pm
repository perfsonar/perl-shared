package perfSONAR_PS::NPToolkit::Config::PSConfigParser;
#BaseAgent.pm (perfSONAR_PS/PSConfig/ )

use Mouse;

use CHI;
use Data::Dumper;
use Data::Validate::Domain qw(is_hostname);
use Data::Validate::IP qw(is_ipv4 is_ipv6 is_loopback_ipv4);
use Net::CIDR qw(cidrlookup);
use File::Basename;
use JSON qw/ from_json /;
use Log::Log4perl qw(get_logger);
use URI;

use perfSONAR_PS::Client::PSConfig::ApiConnect;
use perfSONAR_PS::Client::PSConfig::ApiFilters;
use perfSONAR_PS::Client::PSConfig::Archive;
use perfSONAR_PS::Client::PSConfig::Config;

use perfSONAR_PS::Client::PSConfig::Parsers::TaskGenerator;
#use perfSONAR_PS::PSConfig::ArchiveConnect;
#use perfSONAR_PS::Utils::Logging;
#use perfSONAR_PS::PSConfig::RequestingAgentConnect;
#use perfSONAR_PS::PSConfig::TransformConnect;
#use perfSONAR_PS::Utils::DNS qw(resolve_address reverse_dns);
#use perfSONAR_PS::Utils::Host qw(get_ips);
#use perfSONAR_PS::Utils::ISO8601 qw/duration_to_seconds/;

our $VERSION = 4.1;


has 'config_file' => (is => 'rw', isa => 'Str', default => '/etc/perfsonar/psconfig/pscheduler.d/toolkit-webui.json');
has 'psconfig' => (is => 'rw', isa => 'perfSONAR_PS::Client::PSConfig::Config', default => sub { new perfSONAR_PS::Client::PSConfig::Config(); });


has 'task_name' => (is => 'rw', isa => 'Str');
has 'match_addresses' => (is => 'rw', isa => 'ArrayRef[Str]', default => sub {[]});
has 'pscheduler_url' => (is => 'rw', isa => 'Str');
has 'default_archives' => (is => 'rw', isa => 'ArrayRef[perfSONAR_PS::Client::PSConfig::Archive]', default => sub { [] });
has 'use_psconfig_archives' => (is => 'rw', isa => 'Bool', default => sub { 1 });
has 'bind_map' => (is => 'rw', isa => 'HashRef', default => sub { {} });

#read-only
###Updated whenever an error occurs
has 'error' => (is => 'ro', isa => 'Str|Undef', writer => '_set_error');
###Updated on call to start()
has 'started' => (is => 'ro', isa => 'Bool', writer => '_set_started');
has 'task' => (is => 'ro', isa => 'perfSONAR_PS::Client::PSConfig::Task|Undef', writer => '_set_task');
has 'group' => (is => 'ro', isa => 'perfSONAR_PS::Client::PSConfig::Groups::BaseGroup|Undef', writer => '_set_group');
has 'schedule' => (is => 'ro', isa => 'perfSONAR_PS::Client::PSConfig::Schedule|Undef', writer => '_set_schedule');
has 'tools' => (is => 'ro', isa => 'ArrayRef[Str]|Undef', writer => '_set_tools');
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
#


#private
has '_match_addresses_map' => (is => 'ro', isa => 'HashRef|Undef', writer => '_set_match_addresses_map');


#sub new {
#    print ("\n\nKONSTRUKTOR\n\n");
#}

sub init {
    # my ( $class, @params ) = @_;
    my ( $self, $params) = @_;
    my $config_file = $params if $params;

    $self->config_file("/etc/perfsonar/psconfig/pscheduler.d/toolkit-webui.json");
    print ("init parametar " . $self->config_file . "\n");

    my $json_text = do {
        open(my $json_fh, "<:encoding(UTF-8)", $self->config_file)
 	    or die("Can't open \"$self->config_file\": $!\n");
        local $/;
     	<$json_fh>
    };
    
    my $json = JSON->new;
    my $data = $json->decode($json_text);
    # my $config_obj = from_json($config_json);

    #print ("init json " . $data . "\n");
    #######
    ### Initialize psconfig
    ##########
    my $psconfig = new perfSONAR_PS::Client::PSConfig::Config(data => $data);
    $self->psconfig($psconfig);
    ##is($psconfig->validate(), 0);
    ##
#    my $config_file = $self->config_file();

#    my $self = fields::new( $class );

    $self->config_file('/etc/perfsonar/psconfig/pscheduler.d/toolkit-webui.json'); # $config_file);
    # $self->config_file($config_file);
    # print ("init self " . $self->config_file . "\n\t " . Dumper($self->psconfig) . "\n");
}

sub get_tasks() {
    my $self = shift;    
    #get tasks
    #PScheduler TaskGenerator
    #my $existing_tasks = $self->psconfig->get_tasks();
    my $existing_tasks = $self->psconfig->_get_map_names("tasks");
    #print("tasks ".@existing_tasks);
    print("tasks ".Dumper($existing_tasks));

    if ($existing_tasks && $existing_tasks > 0 && $self->psconfig->error()) {
        #there was an error getting an individual task
	$self->log_error("Error fetching an individual task, but was able to get list: " .  $self->psconfig->error());
    } elsif($self->psconfig->error()) {
        #there was an error getting the entire list
	$self->log_error("Error getting task list: " . $self->psconfig->error());
	#push @{$self->errors()}, "Problem getting existing tests from pScheduler lead $psc_url: ".$psconfig->error();
	#next;
    } elsif ($existing_tasks == 0) {
        #TODO: Drop this when 4.0 deprecated. fallback in case detail filter not supported (added in 4.0.2).
	$self->log_debug("Trying to get task list without enabled filter");
    } else {
	    # print("JOVANA finding tasks " . ref($existing_tasks) . " " . ref($existing_tasks[0]) . "\n");
	foreach my $task_name(@{$existing_tasks}[0]) {
            print("" . ref($task_name) . " " . Dumper($task_name) . "\n");
	    #find task
            my $task = $self->psconfig()->task($task_name);
	    if ($task) {
                $self->_set_task($task);
	    } else { 
                print("Unable to find a task with name " . $self->task_name());
                $self->_set_error("Unable to find a task with name " . $self->task_name());
	    }
	    print("task: " . Dumper($self->task));

            #find group
	    my $group = $self->psconfig()->group($task->group_ref());
	    if($group) {
                $self->_set_group($group);
	    } else {
		print("Unable to find a group with name " . $task->group_ref());
		$self->_set_error("Unable to find a group with name " . $task->group_ref());
            }
	    print("group: " . Dumper($self->group));

            #find test
	    my $test = $self->psconfig()->test($task->test_ref());
	    if ($test) {
                $self->_set_test($test);
	    } else {
                print("Unable to find a test with name " . $task->test_ref());
                $self->_set_error("Unable to find a test with name " . $task->test_ref());
	    }
	    print("test: " . Dumper($self->test));

            #find schedule (optional)
	    my $schedule = $self->psconfig()->schedule($task->schedule_ref());
	    if ($schedule) {
                $self->_set_schedule($schedule);
	    }
	    print("schedule: " . Dumper($self->schedule));

	    #find tools (optional) 
	    my $tools = $task->tools();
	    if ($tools && @{$tools}) {
                $self->_set_tools($tools);
	    }
	    print("tools: " . Dumper($self->tools));

            #find priority (optional)
	    my $priority = $task->priority();
	    if (defined $priority){
                $self->_set_priority($priority);
            }
	    print("priorioty: " . Dumper($self->priority));

            #set match addresses if any
	    if(@{$self->match_addresses()} > 0){
		print("".(@{$self->match_addresses()} > 0));
                my %match_addresses_map = map { lc($_) => 1 } @{$self->match_addresses()};
		$self->_set_match_addresses_map(\%match_addresses_map);
	    } else {
		print("self->match_addresses() undef");
		$self->_set_match_addresses_map(undef);
	    }
	    print("match-address-map: " . Dumper($self->match_addresses));
            $self->expand_task;
	    print("priorioty: " . Dumper($self->expanded_test));
	}
    }
}

sub expand_task {
    my $self = shift;
    #clear out stuff set each next iteration
    $self->_reset();
    
    #find the next test we have to run
    my $scheduled_by = $self->task()->scheduled_by() ?  $self->task()->scheduled_by() : 0;
    my @addrs;
    my $matched = 0;
    my $flip = 0;
    my $scheduled_by_addr;
    print("expand_task 1\n");
    print("expand_task group ref ".ref($self->group()));
    print("expand_task group ".Dumper($self->group()));
    #print("expand_task group->meta ".Dumper($self->group()->meta));
    #print("expand_task group->next ".Dumper($self->group()->next()));
    #while(@addrs = $self->group()->next()){
    while(@addrs = $self->group()->data()){
	print("expanding_task addresses ".Dumper(@addrs));
        #validate scheduled by
        if($scheduled_by >= @addrs){
            $self->_set_error("The scheduled-by property for task  " . $self->task_name() . " is too big. It is set to $scheduled_by but must not be bigger than " . @addrs);
            return;
        }
        
        #check if disabled
	#my $disabled = 0;
	#foreach my $addr(@addrs){
	#    if($self->_is_disabled($addr)){
	#        $disabled = 1;
	#        last;
	#    }
	#}
	#next if($disabled);
        
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
    print("expand_task 2\n");
    
    #if no match, then exit
    unless($matched){
        return;
    }
    print("expand_task 3\n");
    
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
    print("expanding test:" . $self->test);
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

sub _reset {
    my ($self) = @_;
    
    $self->_set_error(undef);
    $self->_set_expanded_test(undef);
    $self->_set_expanded_archives(undef);
    $self->_set_expanded_contexts(undef);
    $self->_set_expanded_reference(undef);
    $self->_set_scheduled_by_address(undef);
    $self->_set_addresses(undef);
}
 

sub init1 {
    # my ( $class, @params ) = @_;
    my ( $self, $params) = @_;
    my $config_file = $params if $params;

#    my $self = fields::new( $class );

    print ("konstruktor " . $config_file . "\n");
    $self->config_file('/etc/perfsonar/psconfig/pscheduler.d/toolkit-webui.json'); # $config_file);
    # $self->config_file($config_file);
   
}

sub _read_config_file {
    my ($self, $psconfig_client, $transform) = @_;
#    my $class = shift;
    #my ($self, $psconfig_client) = @_;
	my $ja = new perfSONAR_PS::NPToolkit::Config::PSConfigParser;
	$ja->init("/etc/perfsonar/psconfig/pscheduler.d/toolkit-webui.json");

    print "JOVANA: " . $ja->config_file();



    if (0) {
        my $abs_file = $self->config_file();

        my $log_ctx = {"template_file" => $abs_file};
	# $logger->debug($self->logf()->format("Loading include file $abs_file", $log_ctx));
        #create client
        my $psconfig_client = new perfSONAR_PS::Client::PSConfig::ApiConnect(
            url => $abs_file
        );

#        my $processed_psconfig = $self->_process_psconfig($psconfig_client);
#        return $processed_psconfig;
        return $psconfig_client;
    }
}

__PACKAGE__->meta->make_immutable;

1;

