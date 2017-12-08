package perfSONAR_PS::Client::PSConfig::Config;

use Mouse;
use JSON::Validator;
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

#HashRef of "name" => "address"
has 'requesting_agent_addresses' => (is => 'rw', isa => 'HashRef', default => sub {{}});
has 'error' => (is => 'ro', isa => 'Str', writer => '_set_error');

sub addresses{
    my ($self, $val) = @_;
    
    return $self->_field_class_map('addresses', 'perfSONAR_PS::Client::PSConfig::Addresses::Address', $val);
}

sub address{
    my ($self, $field, $val) = @_;
    
    return $self->_field_class_map_item('addresses', $field, 'perfSONAR_PS::Client::PSConfig::Addresses::Address', $val);
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
    
    return $self->_field_class_map('address-classes', 'perfSONAR_PS::Client::PSConfig::AddressClasses::AddressClass', $val);
}

sub address_class{
    my ($self, $field, $val) = @_;
    
    return $self->_field_class_map_item('address-classes', $field, 'perfSONAR_PS::Client::PSConfig::AddressClasses::AddressClass', $val);
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
    
    return $self->_field_class_map('archives', 'perfSONAR_PS::Client::PSConfig::Archive', $val);
}

sub archive{
    my ($self, $field, $val) = @_;
    
    return $self->_field_class_map_item('archives', $field, 'perfSONAR_PS::Client::PSConfig::Archive', $val);
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
    
    return $self->_field_class_map('contexts', 'perfSONAR_PS::Client::PSConfig::Context', $val);
}

sub context{
    my ($self, $field, $val) = @_;
    
    return $self->_field_class_map_item('contexts', $field, 'perfSONAR_PS::Client::PSConfig::Context', $val);
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
    return $self->_field_class_factory_map(
        'groups', 
        'perfSONAR_PS::Client::PSConfig::Groups::BaseGroup', 
        'perfSONAR_PS::Client::PSConfig::Groups::GroupFactory',
        $val
    );
}

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
    return $self->_field_class_map('hosts', 'perfSONAR_PS::Client::PSConfig::Host', $val);
}

sub host{
    my ($self, $field, $val) = @_;
    return $self->_field_class_map_item('hosts', $field, 'perfSONAR_PS::Client::PSConfig::Host', $val);
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
    return $self->_field_class_map('schedules', 'perfSONAR_PS::Client::PSConfig::Schedule', $val);
}

sub schedule{
    my ($self, $field, $val) = @_;
    return $self->_field_class_map_item('schedules', $field, 'perfSONAR_PS::Client::PSConfig::Schedule', $val);
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
    return $self->_field_class_map('subtasks', 'perfSONAR_PS::Client::PSConfig::Subtask', $val);
}

sub subtask{
    my ($self, $field, $val) = @_;
    return $self->_field_class_map_item('subtasks', $field, 'perfSONAR_PS::Client::PSConfig::Subtask', $val);
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
    return $self->_field_class_map('tasks', 'perfSONAR_PS::Client::PSConfig::Task', $val);
}

sub task{
    my ($self, $field, $val) = @_;
    return $self->_field_class_map_item('tasks', $field, 'perfSONAR_PS::Client::PSConfig::Task', $val);
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
    return $self->_field_class_map('tests', 'perfSONAR_PS::Client::PSConfig::Test', $val);
}

sub test{
    my ($self, $field, $val) = @_;
    return $self->_field_class_map_item('tests', $field, 'perfSONAR_PS::Client::PSConfig::Test', $val);
}

sub test_names{
    my ($self) = @_;
    return $self->_get_map_names("tests");
} 

sub remove_test {
    my ($self, $field) = @_;
    $self->_remove_map_item('tests', $field);
}


sub validate {
    my $self = shift;
    my $validator = new JSON::Validator();
    $validator->schema(psconfig_json_schema());

    return $validator->validate($self->data());
}


__PACKAGE__->meta->make_immutable;

1;
