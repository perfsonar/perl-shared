package perfSONAR_PS::Client::PSConfig::Config;

use Mouse;
use JSON qw(to_json);
use perfSONAR_PS::Client::PSConfig::Archive;
use perfSONAR_PS::Client::PSConfig::Schedule;
use perfSONAR_PS::Client::PSConfig::Test;
use perfSONAR_PS::Client::PSConfig::Context;
use perfSONAR_PS::Client::PSConfig::Groups::BaseGroup;
use perfSONAR_PS::Client::PSConfig::Groups::GroupFactory;
use perfSONAR_PS::Client::PSConfig::AddressClasses::AddressClass;

extends 'perfSONAR_PS::Client::PSConfig::BaseMetaNode';

has 'error' => (is => 'ro', isa => 'Str', writer => '_set_error');

sub addresses{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->data->{'addresses'} = {};
        foreach my $v(keys %{$val}){
            my $tmp_addr = $val->{$v}->data;
            $self->data->{'addresses'}->{$v} = $tmp_addr;
        }
    }
    
    my %addresses = ();
    foreach my $addr(keys %{$self->data->{'addresses'}}){
        my $tmp_addr_obj = $self->address($addr);
        $addresses{$addr} = $tmp_addr_obj;
    }
    
    return \%addresses;
}

sub address{
    my ($self, $field, $val) = @_;
    
    unless(defined $field){
        return undef;
    }
    
    if(defined $val){
        $self->_init_field($self->data, 'addresses');
        $self->data->{'addresses'}->{$field} = $val->data;
    }
    
    unless($self->_has_field($self->data, "addresses")){
        return undef;
    }
    
    unless($self->_has_field($self->data->{'addresses'}, $field)){
        return undef;
    }
    
    return new perfSONAR_PS::Client::PSConfig::Addresses::Address(
            data => $self->data->{'addresses'}->{$field}
        );
} 

sub address_names{
    my ($self) = @_;
    return $self->_get_map_names("addresses");
} 

sub remove_address {
    my ($self, $field) = @_;
    $self->_remove_map_item('addresses', $field);
}

sub address_classes{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->data->{'address-classes'} = {};
        foreach my $v(keys %{$val}){
            my $tmp_addr_class = $val->{$v}->data;
            $self->data->{'address-classes'}->{$v} = $tmp_addr_class;
        }
    }
    
    my %address_classes = ();
    foreach my $addr_class(keys %{$self->data->{'address-classes'}}){
        my $tmp_addr_class_obj = $self->address_class($addr_class);
        $address_classes{$addr_class} = $tmp_addr_class_obj;
    }
    
    return \%address_classes;
}

sub address_class{
    my ($self, $field, $val) = @_;
    
    unless(defined $field){
        return undef;
    }
    
    if(defined $val){
        $self->_init_field($self->data, 'address-classes');
        $self->data->{'address-classes'}->{$field} = $val->data;
    }
    
    unless($self->_has_field($self->data, "address-classes")){
        return undef;
    }
    
    unless($self->_has_field($self->data->{'address-classes'}, $field)){
        return undef;
    }
    
    return new perfSONAR_PS::Client::PSConfig::AddressClasses::AddressClass(
            data => $self->data->{'address-classes'}->{$field}
        );
} 

sub address_class_names{
    my ($self) = @_;
    return $self->_get_map_names("address-classes");
} 

sub remove_address_class {
    my ($self, $field) = @_;
    $self->_remove_map_item('address-classes', $field);
}

sub archives{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->data->{'archives'} = {};
        foreach my $v(keys %{$val}){
            my $tmp_archive = $val->{$v}->data;
            $self->data->{'archives'}->{$v} = $tmp_archive;
        }
    }
    
    my %archives = ();
    foreach my $archive(keys %{$self->data->{'archives'}}){
        my $tmp_archive_obj = $self->archive($archive);
        $archives{$archive} = $tmp_archive_obj;
    }
    
    return \%archives;
}

sub archive{
    my ($self, $field, $val) = @_;
    
    unless(defined $field){
        return undef;
    }
    
    if(defined $val){
        $self->_init_field($self->data, 'archives');
        $self->data->{'archives'}->{$field} = $val->data;
    }
    
    unless($self->_has_field($self->data, "archives")){
        return undef;
    }
    
    unless($self->_has_field($self->data->{'archives'}, $field)){
        return undef;
    }
    
    return new perfSONAR_PS::Client::PSConfig::Archive(
            data => $self->data->{'archives'}->{$field}
        );
} 

sub archive_names{
    my ($self) = @_;
    return $self->_get_map_names("archives");
} 

sub remove_archive {
    my ($self, $field) = @_;
    $self->_remove_map_item('archives', $field);
}

sub contexts{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->data->{'contexts'} = {};
        foreach my $v(keys %{$val}){
            my $tmp_context = $val->{$v}->data;
            $self->data->{'contexts'}->{$v} = $tmp_context;
        }
    }
    
    my %contexts = ();
    foreach my $context(keys %{$self->data->{'contexts'}}){
        my $tmp_context_obj = $self->context($context);
        $contexts{$context} = $tmp_context_obj;
    }
    
    return \%contexts;
}

sub context{
    my ($self, $field, $val) = @_;
    
    unless(defined $field){
        return undef;
    }
    
    if(defined $val){
        $self->_init_field($self->data, 'contexts');
        $self->data->{'contexts'}->{$field} = $val->data;
    }
    
    unless($self->_has_field($self->data, "contexts")){
        return undef;
    }
    
    unless($self->_has_field($self->data->{'contexts'}, $field)){
        return undef;
    }
    
    return new perfSONAR_PS::Client::PSConfig::Context(
            data => $self->data->{'contexts'}->{$field}
        );
} 

sub context_names{
    my ($self) = @_;
    return $self->_get_map_names("contexts");
} 

sub remove_context {
    my ($self, $field) = @_;
    $self->_remove_map_item('contexts', $field);
}

sub groups{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->data->{'groups'} = {};
        foreach my $v(keys %{$val}){
            my $tmp_group = $val->{$v}->data;
            $self->data->{'groups'}->{$v} = $tmp_group;
        }
    }
    
    my %groups = ();
    foreach my $group(keys %{$self->data->{'groups'}}){
        my $tmp_group_obj = $self->group($group);
        $groups{$group} = $tmp_group_obj;
    }
    
    return \%groups;
}

sub group{
    my ($self, $field, $val) = @_;
    
    unless(defined $field){
        return undef;
    }
    
    if(defined $val){
        $self->_init_field($self->data, 'groups');
        $self->data->{'groups'}->{$field} = $val->data;
    }
    
    unless($self->_has_field($self->data, "groups")){
        return undef;
    }
    
    unless($self->_has_field($self->data->{'groups'}, $field)){
        return undef;
    }
    
    my $group_factory = new perfSONAR_PS::Client::PSConfig::Groups::GroupFactory();
    return $group_factory->build($self->data->{'groups'}->{$field});
} 

sub group_names{
    my ($self) = @_;
    return $self->_get_map_names("groups");
} 

sub remove_group {
    my ($self, $field) = @_;
    $self->_remove_map_item('groups', $field);
}

sub hosts{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->data->{'hosts'} = {};
        foreach my $v(keys %{$val}){
            my $tmp_host = $val->{$v}->data;
            $self->data->{'hosts'}->{$v} = $tmp_host;
        }
    }
    
    my %hosts = ();
    foreach my $host(keys %{$self->data->{'hosts'}}){
        my $tmp_host_obj = $self->host($host);
        $hosts{$host} = $tmp_host_obj;
    }
    
    return \%hosts;
}

sub host{
    my ($self, $field, $val) = @_;
    
    unless(defined $field){
        return undef;
    }
    
    if(defined $val){
        $self->_init_field($self->data, 'hosts');
        $self->data->{'hosts'}->{$field} = $val->data;
    }
    
    unless($self->_has_field($self->data, "hosts")){
        return undef;
    }
    
    unless($self->_has_field($self->data->{'hosts'}, $field)){
        return undef;
    }
    
    return new perfSONAR_PS::Client::PSConfig::Host(
            data => $self->data->{'hosts'}->{$field}
        );
} 

sub host_names{
    my ($self) = @_;
    return $self->_get_map_names("hosts");
} 

sub remove_host {
    my ($self, $field) = @_;
    $self->_remove_map_item('hosts', $field);
}

sub includes{
    my ($self, $val) = @_;
    return $self->_field('includes', $val);
}

sub add_include{
    my ($self, $val) = @_;
    $self->_add_list_item('includes', $val);
}

sub schedules{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->data->{'schedules'} = {};
        foreach my $v(keys %{$val}){
            my $tmp_schedule = $val->{$v}->data;
            $self->data->{'schedules'}->{$v} = $tmp_schedule;
        }
    }
    
    my %schedules = ();
    foreach my $schedule(keys %{$self->data->{'schedules'}}){
        my $tmp_schedule_obj = $self->schedule($schedule);
        $schedules{$schedule} = $tmp_schedule_obj;
    }
    
    return \%schedules;
}

sub schedule{
    my ($self, $field, $val) = @_;
    
    unless(defined $field){
        return undef;
    }
    
    if(defined $val){
        $self->_init_field($self->data, 'schedules');
        $self->data->{'schedules'}->{$field} = $val->data;
    }
    
    unless($self->_has_field($self->data, "schedules")){
        return undef;
    }
    
    unless($self->_has_field($self->data->{'schedules'}, $field)){
        return undef;
    }
    
    return new perfSONAR_PS::Client::PSConfig::Schedule(
            data => $self->data->{'schedules'}->{$field}
        );
} 

sub schedule_names{
    my ($self) = @_;
    return $self->_get_map_names("schedules");
} 

sub remove_schedule {
    my ($self, $field) = @_;
    $self->_remove_map_item('schedules', $field);
}

sub subtasks{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->data->{'subtasks'} = {};
        foreach my $v(keys %{$val}){
            my $tmp_task = $val->{$v}->data;
            $self->data->{'subtasks'}->{$v} = $tmp_task;
        }
    }
    
    my %tasks = ();
    foreach my $task(keys %{$self->data->{'subtasks'}}){
        my $tmp_task_obj = $self->subtask($task);
        $tasks{$task} = $tmp_task_obj;
    }
    
    return \%tasks;
}

sub subtask{
    my ($self, $field, $val) = @_;
    
    unless(defined $field){
        return undef;
    }
    
    if(defined $val){
        $self->_init_field($self->data, 'subtasks');
        $self->data->{'subtasks'}->{$field} = $val->data;
    }
    
    unless($self->_has_field($self->data, "subtasks")){
        return undef;
    }
    
    unless($self->_has_field($self->data->{'subtasks'}, $field)){
        return undef;
    }
    
    return new perfSONAR_PS::Client::PSConfig::Subtask(
            data => $self->data->{'subtasks'}->{$field}
        );
} 

sub subtask_names{
    my ($self) = @_;
    return $self->_get_map_names("subtasks");
} 

sub remove_subtask {
    my ($self, $field) = @_;
    $self->_remove_map_item('subtasks', $field);
}


sub tasks{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->data->{'tasks'} = {};
        foreach my $v(keys %{$val}){
            my $tmp_task = $val->{$v}->data;
            $self->data->{'tasks'}->{$v} = $tmp_task;
        }
    }
    
    my %tasks = ();
    foreach my $task(keys %{$self->data->{'tasks'}}){
        my $tmp_task_obj = $self->task($task);
        $tasks{$task} = $tmp_task_obj;
    }
    
    return \%tasks;
}

sub task{
    my ($self, $field, $val) = @_;
    
    unless(defined $field){
        return undef;
    }
    
    if(defined $val){
        $self->_init_field($self->data, 'tasks');
        $self->data->{'tasks'}->{$field} = $val->data;
    }
    
    unless($self->_has_field($self->data, "tasks")){
        return undef;
    }
    
    unless($self->_has_field($self->data->{'tasks'}, $field)){
        return undef;
    }
    
    return new perfSONAR_PS::Client::PSConfig::Task(
            data => $self->data->{'tasks'}->{$field}
        );
} 

sub task_names{
    my ($self) = @_;
    return $self->_get_map_names("tasks");
} 

sub remove_task {
    my ($self, $field) = @_;
    $self->_remove_map_item('tasks', $field);
}

sub tests{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->data->{'tests'} = {};
        foreach my $v(keys %{$val}){
            my $tmp_test = $val->{$v}->data;
            $self->data->{'tests'}->{$v} = $tmp_test;
        }
    }
    
    my %tests = ();
    foreach my $test(keys %{$self->data->{'tests'}}){
        my $tmp_test_obj = $self->test($test);
        $tests{$test} = $tmp_test_obj;
    }
    
    return \%tests;
}

sub test{
    my ($self, $field, $val) = @_;
    
    unless(defined $field){
        return undef;
    }
    
    if(defined $val){
        $self->_init_field($self->data, 'tests');
        $self->data->{'tests'}->{$field} = $val->data;
    }
    
    unless($self->_has_field($self->data, "tests")){
        return undef;
    }
    
    unless($self->_has_field($self->data->{'tests'}, $field)){
        return undef;
    }
    
    return new perfSONAR_PS::Client::PSConfig::Test(
            data => $self->data->{'tests'}->{$field}
        );
} 

sub test_names{
    my ($self) = @_;
    return $self->_get_map_names("tests");
} 

sub remove_test {
    my ($self, $field) = @_;
    $self->_remove_map_item('tests', $field);
}


# sub validate {
#     my $self = shift;
#     
#     #TODO
#     
#     return 0;
# }


__PACKAGE__->meta->make_immutable;

1;
