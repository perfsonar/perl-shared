package perfSONAR_PS::RegularTesting::Tests::Base;

use strict;
use warnings;

our $VERSION = 3.4;

use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);

use perfSONAR_PS::RegularTesting::Utils qw(parse_target);

use Moose;
use Class::MOP::Class;

extends 'perfSONAR_PS::RegularTesting::Utils::SerializableObject';

my $logger = get_logger(__PACKAGE__);

sub type {
    die("'type' needs to be overridden");
}

sub handles_own_scheduling {
    return;
}

sub valid_schedule {
    return 1;
}

sub init_test {
    die("'run_test' needs to be overridden");
}

sub run_test {
    die("'run_test' needs to be overridden");
}

sub stop_test {
    die("'stop_test' needs to be overridden");
}

sub to_pscheduler {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { 
                                         url => 1,
                                         test => 1,
                                         archive_map => 1,
                                         task_manager => 1
                                      });
    die "Not implemented. Must be overridden by subclass.";
}

sub default_retry_policy {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { 
                                         interval => 1
                                      });
    my $interval = $parameters->{interval};
    
    #init
    my $ttl = 3 *  $interval; #only keep around test for up to 3 times its interval
    if($ttl < 60){
        return; #no retry policy for a test with an interval less than 20 seconds
    }
    
    #build retries
    my @retry = ({"attempts" => 1, "wait" => "PT60S"}); #start off with one attempt after 60 seconds
    my $time = 360;
    my $total_retry_count = 0;
    my $curr_wait = 300; #5 minutes
    my $curr_attempts = 0;
    while ($time < $ttl){
        $curr_attempts++;
        $total_retry_count++;
        if($total_retry_count == 1){
             push @retry, {'attempts' => $curr_attempts, 'wait' => 'PT' . $curr_wait . 'S'};
             $curr_attempts = 0;
             $curr_wait = 3600; #bump to every hour
        }elsif($total_retry_count == 25){
            push @retry, {'attempts' => $curr_attempts, 'wait' => 'PT' . $curr_wait . 'S'};
            $curr_attempts = 0;
            $curr_wait = 86400; #bump to every day
        }
        
        $time += $curr_wait;
    }
    #add the last retry
    push @retry, {'attempts' => $curr_attempts, 'wait' => 'PT' . $curr_wait . 'S'} if($curr_attempts);
    
    return {'ttl' => 'PT' . $ttl . 'S', 'retry' => \@retry};
}

sub valid_target {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {
                                         target => 0,
                                      });
    my $target = $parameters->{target};

    my $parsed_target = parse_target({ target => $target });
    unless ($parsed_target) {
        return;
    }

    return 1;
}

sub psc_test_interval {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {
                                         schedule => 1,
                                         psc_task => 1,
                                      });
    my $psc_task = $parameters->{psc_task};
    my $schedule = $parameters->{schedule};
    #only works for regular_intervals schedules
    if ($schedule->type ne "regular_intervals") {
        return;
    }
    
    #by default set interval to given interval
    $psc_task->schedule_repeat('PT' . $schedule->interval . 'S') if(defined $schedule->interval);
    #allow a test to be scheduled anytime before the next scheduled run by default
    if(defined $schedule->interval){
        if($schedule->interval >= 43200){
            #set a maximum slip of 12 hours to prevent bumping into time horizon
            $psc_task->schedule_slip('PT43200S');
        }else{
            $psc_task->schedule_slip('PT' . $schedule->interval . 'S');
        }
    }
    #by default will randomize (see class definition of RegularIntervals for default)
    $psc_task->schedule_sliprand($schedule->slip_randomize());
    if(defined $schedule->slip){
        #prefer slip if given
        $psc_task->schedule_slip('PT' . $schedule->slip . 'S') if(defined $schedule->slip);
    }elsif(defined $schedule->random_start_percentage && defined $schedule->interval){
        #DEPRECATED
        #always randomize if this option set
        $psc_task->schedule_sliprand(1);
        #change interval to lower bound
        #my $p = int(($schedule->random_start_percentage/100.0) * $schedule->interval);
        #my $lower_bound = $schedule->interval - $p;
        #my $slip = $p * 2;
        #$psc_task->schedule_repeat('PT' . int($lower_bound) . 'S') if(defined $schedule->interval);
        #$psc_task->schedule_slip('PT' . int($slip) . 'S') if(defined $schedule->interval);
    }
}

sub allows_bidirectional {
    return 0;
}

1;
