package perfSONAR_PS::Client::PSConfig::Config;

use Mouse;

use JSON::Validator;
#Ignore warning related to re-defining host verification method used by JSON::Validator
no warnings 'redefine';
use Data::Validate::Domain;

use perfSONAR_PS::Client::PSConfig::Archive;
use perfSONAR_PS::Client::PSConfig::Host;
use perfSONAR_PS::Client::PSConfig::Schedule;
use perfSONAR_PS::Client::PSConfig::Task;
use perfSONAR_PS::Client::PSConfig::Test;
use perfSONAR_PS::Client::PSConfig::Context;
use perfSONAR_PS::Client::PSConfig::Groups::BaseGroup;
use perfSONAR_PS::Client::PSConfig::Groups::GroupFactory;
use perfSONAR_PS::Client::PSConfig::AddressClasses::AddressClass;
use perfSONAR_PS::Client::PSConfig::Schema qw(psconfig_json_schema);

extends 'perfSONAR_PS::Client::PSConfig::BaseMetaNode';

has 'requesting_agent_addresses' => (is => 'rw', isa => 'HashRef', default => sub {{}});
has 'error' => (is => 'ro', isa => 'Str', writer => '_set_error');

=item addresses()

Get/sets addresses as HashRef

=cut

sub addresses{
    my ($self, $val) = @_;
    
    return $self->_field_class_map('addresses', 'perfSONAR_PS::Client::PSConfig::Addresses::Address', $val);
}

=item address()

Get/sets address at specified field

=cut

sub address{
    my ($self, $field, $val) = @_;
    
    return $self->_field_class_map_item('addresses', $field, 'perfSONAR_PS::Client::PSConfig::Addresses::Address', $val);
}

=item address_names()

Gets keys of addresses HashRef

=cut

sub address_names{
    my ($self) = @_;
    return $self->_get_map_names("addresses");
} 

=item remove_address()

Removes address at specified field

=cut

sub remove_address {
    my ($self, $field) = @_;
    $self->_remove_map_item('addresses', $field);
}

=item address_classes()

Get/sets addresses-classes as HashRef

=cut

sub address_classes{
    my ($self, $val) = @_;
    
    return $self->_field_class_map('address-classes', 'perfSONAR_PS::Client::PSConfig::AddressClasses::AddressClass', $val);
}

=item address_class()

Get/sets address-class at specified field

=cut

sub address_class{
    my ($self, $field, $val) = @_;
    
    return $self->_field_class_map_item('address-classes', $field, 'perfSONAR_PS::Client::PSConfig::AddressClasses::AddressClass', $val);
}

=item address_class_names()

Gets keys of addresses-classes HashRef

=cut

sub address_class_names{
    my ($self) = @_;
    return $self->_get_map_names("address-classes");
} 

=item remove_address_class()

Removes address-class at specified field

=cut

sub remove_address_class {
    my ($self, $field) = @_;
    $self->_remove_map_item('address-classes', $field);
}

=item archives()

Get/sets archives as HashRef

=cut

sub archives{
    my ($self, $val) = @_;
    
    return $self->_field_class_map('archives', 'perfSONAR_PS::Client::PSConfig::Archive', $val);
}

=item archive()

Get/sets archive at specified field

=cut

sub archive{
    my ($self, $field, $val) = @_;
    
    return $self->_field_class_map_item('archives', $field, 'perfSONAR_PS::Client::PSConfig::Archive', $val);
}

=item archive_names()

Gets keys of archives HashRef

=cut

sub archive_names{
    my ($self) = @_;
    return $self->_get_map_names("archives");
} 

=item remove_archive()

Removes archive at specified field

=cut

sub remove_archive {
    my ($self, $field) = @_;
    $self->_remove_map_item('archives', $field);
}

=item contexts()

Get/sets contexts as HashRef

=cut

sub contexts{
    my ($self, $val) = @_;
    
    return $self->_field_class_map('contexts', 'perfSONAR_PS::Client::PSConfig::Context', $val);
}

=item context()

Get/sets context at specified field

=cut

sub context{
    my ($self, $field, $val) = @_;
    
    return $self->_field_class_map_item('contexts', $field, 'perfSONAR_PS::Client::PSConfig::Context', $val);
}

=item context_names()

Gets keys of contexts HashRef

=cut

sub context_names{
    my ($self) = @_;
    return $self->_get_map_names("contexts");
} 

=item remove_context()

Removes context at specified field

=cut

sub remove_context {
    my ($self, $field) = @_;
    $self->_remove_map_item('contexts', $field);
}

=item groups()

Get/sets groups as HashRef

=cut

sub groups{
    my ($self, $val) = @_;
    return $self->_field_class_factory_map(
        'groups', 
        'perfSONAR_PS::Client::PSConfig::Groups::BaseGroup', 
        'perfSONAR_PS::Client::PSConfig::Groups::GroupFactory',
        $val
    );
}

=item group()

Get/sets group at specified field

=cut

sub group{
    my ($self, $field, $val) = @_;
    return $self->_field_class_factory_map_item(
        'groups', 
        $field, 
        'perfSONAR_PS::Client::PSConfig::Groups::BaseGroup', 
        'perfSONAR_PS::Client::PSConfig::Groups::GroupFactory',
        $val
    );
}

=item group_names()

Gets keys of groups HashRef

=cut

sub group_names{
    my ($self) = @_;
    return $self->_get_map_names("groups");
} 

=item remove_group()

Removes group at specified field

=cut

sub remove_group {
    my ($self, $field) = @_;
    $self->_remove_map_item('groups', $field);
}

=item hosts()

Get/sets hosts as HashRef

=cut

sub hosts{
    my ($self, $val) = @_;
    return $self->_field_class_map('hosts', 'perfSONAR_PS::Client::PSConfig::Host', $val);
}

=item host()

Get/sets host at specified field

=cut

sub host{
    my ($self, $field, $val) = @_;
    return $self->_field_class_map_item('hosts', $field, 'perfSONAR_PS::Client::PSConfig::Host', $val);
}

=item host_names()

Gets keys of hosts HashRef

=cut

sub host_names{
    my ($self) = @_;
    return $self->_get_map_names("hosts");
} 

=item remove_host()

Removes host at specified field

=cut

sub remove_host {
    my ($self, $field) = @_;
    $self->_remove_map_item('hosts', $field);
}

=item includes()

Get/sets includes as ArrayRef

=cut

sub includes{
    my ($self, $val) = @_;
    return $self->_field('includes', $val);
}

=item add_include()

Adds include to list

=cut

sub add_include{
    my ($self, $val) = @_;
    $self->_add_list_item('includes', $val);
}

=item schedules()

Get/sets schedules as HashRef

=cut

sub schedules{
    my ($self, $val) = @_;
    return $self->_field_class_map('schedules', 'perfSONAR_PS::Client::PSConfig::Schedule', $val);
}

=item schedule()

Get/sets schedule at specified field

=cut

sub schedule{
    my ($self, $field, $val) = @_;
    return $self->_field_class_map_item('schedules', $field, 'perfSONAR_PS::Client::PSConfig::Schedule', $val);
}

=item schedule_names()

Gets keys of schedules HashRef

=cut

sub schedule_names{
    my ($self) = @_;
    return $self->_get_map_names("schedules");
} 

=item remove_schedule()

Removes schedule at specified field

=cut

sub remove_schedule {
    my ($self, $field) = @_;
    $self->_remove_map_item('schedules', $field);
}

=item subtasks()

Get/sets subtasks as HashRef

=cut

sub subtasks{
    my ($self, $val) = @_;
    return $self->_field_class_map('subtasks', 'perfSONAR_PS::Client::PSConfig::Subtask', $val);
}

=item subtask()

Get/sets subtask at specified field

=cut

sub subtask{
    my ($self, $field, $val) = @_;
    return $self->_field_class_map_item('subtasks', $field, 'perfSONAR_PS::Client::PSConfig::Subtask', $val);
}

=item subtask_names()

Gets keys of subtasks HashRef

=cut

sub subtask_names{
    my ($self) = @_;
    return $self->_get_map_names("subtasks");
} 

=item remove_subtask()

Removes subtask at specified field

=cut

sub remove_subtask {
    my ($self, $field) = @_;
    $self->_remove_map_item('subtasks', $field);
}

=item tasks()

Get/sets tasks as HashRef

=cut

sub tasks{
    my ($self, $val) = @_;
    return $self->_field_class_map('tasks', 'perfSONAR_PS::Client::PSConfig::Task', $val);
}

=item task()

Get/sets task at specified field

=cut

sub task{
    my ($self, $field, $val) = @_;
    return $self->_field_class_map_item('tasks', $field, 'perfSONAR_PS::Client::PSConfig::Task', $val);
}

=item task_names()

Gets keys of tasks HashRef

=cut

sub task_names{
    my ($self) = @_;
    return $self->_get_map_names("tasks");
} 

=item remove_task()

Removes task at specified field

=cut

sub remove_task {
    my ($self, $field) = @_;
    $self->_remove_map_item('tasks', $field);
}

=item tests()

Get/sets tests as HashRef

=cut

sub tests{
    my ($self, $val) = @_;
    return $self->_field_class_map('tests', 'perfSONAR_PS::Client::PSConfig::Test', $val);
}

=item test()

Get/sets test at specified field

=cut


sub test{
    my ($self, $field, $val) = @_;
    return $self->_field_class_map_item('tests', $field, 'perfSONAR_PS::Client::PSConfig::Test', $val);
}

=item test_names()

Gets keys of tests HashRef

=cut

sub test_names{
    my ($self) = @_;
    return $self->_get_map_names("tests");
} 

=item remove_test()

Removes test at specified field

=cut

sub remove_test {
    my ($self, $field) = @_;
    $self->_remove_map_item('tests', $field);
}

=item validate()

Validates config against JSON schema. Return list of errors if finds any, return empty 
lost otherwise

=cut

sub validate {
    my $self = shift;
    my $validator = new JSON::Validator();
    ##NOTE: Below works around the strict TLD requirements of JSON::Validator
    local *Data::Validate::Domain::is_domain = \&Data::Validate::Domain::is_hostname;
    $validator->schema(psconfig_json_schema());

    return $validator->validate($self->data());
}

sub _ref_check_addr_select{
    my ($self, $addr_sel, $group_name, $psconfig, $errors) = @_;
    
    if($addr_sel->can('name')){
        my $addr_name = $addr_sel->name();
        my $addr_obj = $psconfig->address($addr_name);
        unless($addr_obj){
            push @{$errors}, "Group $group_name references an address object $addr_name that does not exist.";
            return;
        }
        my $addr_label_name = $addr_sel->label();
        if($addr_label_name && !$addr_obj->label($addr_label_name)){
            push @{$errors}, "Group $group_name references a label $addr_label_name for address object $addr_name that does not exist.";
        }
    }elsif($addr_sel->can('class')){
        my $class_name = $addr_sel->class();
        unless($psconfig->address_class()){
            push @{$errors}, "Group $group_name references a class object $class_name that does not exist.";
            return;
        }
    }
}

sub validate_refs {
    my $self = shift;
    my $ref_errors = [];

    #check addresses
    foreach my $addr_name(@{$self->address_names()}){
        my $address = $self->address($addr_name);
        my $host_ref = $address->host_ref();
        my $context_refs = $address->context_refs();
        #check host ref
        if($host_ref && !$self->host($host_ref)){
            push @{$ref_errors}, "Address $addr_name references a host object $host_ref that does not exist.";
        }
        #check context refs
        if($context_refs){
            foreach my $context_ref(@{$context_refs}){
                if(!$self->context($context_ref)){
                    push @{$ref_errors}, "Address $addr_name references a context object $context_ref that does not exist.";
                }
            }
        }
        #check remote addresses
        foreach my $remote_name(@{$address->remote_address_names()}){
            #check remote context refs
            my $remote = $address->remote_address($remote_name);
            if($remote->context_refs()){
                foreach my $context_ref(@{$remote->context_refs()}){
                    if(!$self->context($context_ref)){
                        push @{$ref_errors}, "Address $addr_name has a remote definition for $remote_name using a context object $context_ref that does not exist.";
                    }
                }
            }
            #check remote labels
            foreach my $label_name(@{$remote->label_names()}){
                my $label = $address->label($label_name);
                if($label->context_refs()){
                    foreach my $context_ref(@{$label->context_refs()}){
                        if(!$self->context($context_ref)){
                            push @{$ref_errors}, "Address $addr_name has a label $label_name using a context object $context_ref that does not exist.";
                        }
                    }
                }
            }
        }
        #check labels
        foreach my $label_name(@{$address->label_names()}){
            my $label = $address->label($label_name);
            #check label context refs
            if($label->context_refs()){
                foreach my $context_ref(@{$label->context_refs()}){
                    if(!$self->context($context_ref)){
                        push @{$ref_errors}, "Address $addr_name has a label $label_name using a context object $context_ref that does not exist.";
                    }
                }
            }
        }
    }
    #check groups
    foreach my $group_name(@{$self->group_names()}){
        my $group = $self->group($group_name);
        if($group->type() eq 'disjoint'){
            foreach my $a_addr_sel(@{$group->a_addresses()}){
                $self->_ref_check_addr_select($a_addr_sel, $group_name, $self, $ref_errors);
            }
            foreach my $b_addr_sel(@{$group->b_addresses()}){
                $self->_ref_check_addr_select($b_addr_sel, $group_name, $self, $ref_errors);
            }
        }elsif($group->can('addresses')){
            foreach my $addr_sel(@{$group->addresses()}){
                $self->_ref_check_addr_select($addr_sel, $group_name, $self, $ref_errors);
            }
        }
    }
    #check hosts
    foreach my $host_name(@{$self->host_names()}){
        my $host = $self->host($host_name);
        if($host->archive_refs()){
            foreach my $archive_ref(@{$host->archive_refs()}){
                if($archive_ref && !$self->archive($archive_ref)){
                    push @{$ref_errors}, "Host $host_name references an archive $archive_ref that does not exist.";
                }
            }
        }
    }
    #check tasks
    foreach my $task_name(@{$self->task_names()}){
        my $task = $self->task($task_name);
        my $group_ref = $task->group_ref();
        my $test_ref = $task->test_ref();
        my $schedule_ref = $task->schedule_ref();
        
        #check group ref
        if($group_ref && !$self->group($group_ref)){
            push @{$ref_errors}, "Task $task_name references a group $group_ref that does not exist.";
        }
        #check test ref
        if($test_ref && !$self->test($test_ref)){
            push @{$ref_errors}, "Task $task_name references a test $test_ref that does not exist.";
        }
        #check schedule ref
        if($schedule_ref && !$self->schedule($schedule_ref)){
            push @{$ref_errors}, "Task $task_name references a schedule $schedule_ref that does not exist.";
        }
        #check archive refs
        if($task->archive_refs()){
            foreach my $archive_ref(@{$task->archive_refs()}){
                if($archive_ref && !$self->archive($archive_ref)){
                    push @{$ref_errors}, "Task $task_name references an archive $archive_ref that does not exist.";
                }
            }
        }
    }

    return @{$ref_errors};
}

__PACKAGE__->meta->make_immutable;

1;
