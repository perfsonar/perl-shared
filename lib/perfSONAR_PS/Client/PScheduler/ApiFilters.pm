package perfSONAR_PS::Client::PScheduler::ApiFilters;

use Mouse;

has 'task_filters' => (is => 'rw', isa => 'HashRef', default => sub { {} });
has 'timeout' => (is => 'rw', isa => 'Int', default => sub { 60 });
has 'ca_certificate_file' => (is => 'rw', isa => 'Str|Undef');
has 'ca_certificate_path' => (is => 'rw', isa => 'Str|Undef');
has 'verify_hostname' => (is => 'rw', isa => 'Bool|Undef');

sub test_type{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->_init_filter($self->task_filters, 'test');
        $self->task_filters->{'test'}->{'type'} = $val;
    }
    
    unless($self->_has_filter($self->task_filters, "test")){
        return undef;
    }
    
    return $self->task_filters->{'test'}->{'type'};
}

sub test_spec{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->_init_filter($self->task_filters, 'test');
        $self->task_filters->{'test'}->{'spec'} = $val;
    }
    
    unless($self->_has_filter($self->task_filters, "test")){
        return undef;
    }
    
    return $self->task_filters->{'test'}->{'spec'};
}

sub test_spec_param{
    my ($self, $field, $val) = @_;
    
    unless(defined $field){
        return undef;
    }
    
    if(defined $val){
        $self->_init_filter($self->task_filters, 'test');
        $self->_init_filter($self->task_filters->{'test'}, 'spec');
        $self->task_filters->{'test'}->{'spec'}->{$field} = $val;
    }
    
    unless($self->_has_filter($self->task_filters, "test") && 
                $self->_has_filter($self->task_filters->{'test'}, "spec")){
        return undef;
    }
    
    return $self->task_filters->{'test'}->{'spec'}->{$field};
}


sub tool{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->task_filters->{'tool'} = $val;
    }
    
    return $self->task_filters->{'tool'};
}

sub reference{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->task_filters->{'reference'} = $val;
    }
    
    return $self->task_filters->{'reference'};
}

sub reference_param{
    my ($self, $field, $val) = @_;
    
    unless(defined $field){
        return undef;
    }
    
    if(defined $val){
        $self->_init_filter($self->task_filters, 'reference');
        $self->task_filters->{'reference'}->{$field} = $val;
    }
    
    unless($self->_has_filter($self->task_filters, "reference")){
        return undef;
    }
    
    return $self->task_filters->{'reference'}->{$field};
}

sub schedule{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->task_filters->{'schedule'} = $val;
    }
    
    return $self->task_filters->{'schedule'};
}

sub schedule_maxruns{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->_init_filter($self->task_filters, 'schedule');
        $self->task_filters->{'schedule'}->{'max-runs'} = $val;
    }
    
    unless($self->_has_filter($self->task_filters, "schedule")){
        return undef;
    }
    
    return $self->task_filters->{'schedule'}->{'max-runs'};
}

sub schedule_repeat{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->_init_filter($self->task_filters, 'schedule');
        $self->task_filters->{'schedule'}->{'repeat'} = $val;
    }
    
    unless($self->_has_filter($self->task_filters, "schedule")){
        return undef;
    }
    
    return $self->task_filters->{'schedule'}->{'repeat'};
}

sub schedule_randslip{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->_init_filter($self->task_filters, 'schedule');
        $self->task_filters->{'schedule'}->{'randslip'} = $val;
    }
    
    unless($self->_has_filter($self->task_filters, "schedule")){
        return undef;
    }
    
    return $self->task_filters->{'schedule'}->{'randslip'};
}

sub schedule_slip{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->_init_filter($self->task_filters, 'schedule');
        $self->task_filters->{'schedule'}->{'slip'} = $val;
    }
    
    unless($self->_has_filter($self->task_filters, "schedule")){
        return undef;
    }
    
    return $self->task_filters->{'schedule'}->{'slip'};
}

sub schedule_start{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->_init_filter($self->task_filters, 'schedule');
        $self->task_filters->{'schedule'}->{'start'} = $val;
    }
    
    unless($self->_has_filter($self->task_filters, "schedule")){
        return undef;
    }
    
    return $self->task_filters->{'schedule'}->{'start'};
}

sub archives{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->task_filters->{'archives'} = $val;
    }
    
    return $self->task_filters->{'archives'};
}

sub add_archive_name{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->_init_list_filter($self->task_filters, 'archives');
        push @{$self->task_filters->{'archives'}}, {'name'=> $val};
    }
}

sub add_archive_data{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->_init_list_filter($self->task_filters, 'archives');
        push @{$self->task_filters->{'archives'}}, {'data'=> $val};
    }
}

sub add_archive{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->_init_list_filter($self->task_filters, 'archives');
        push @{$self->task_filters->{'archives'}}, {
                'name' =>  $val->name(),
                'data' =>  $val->data()
            };
    }
}


sub schedule_until{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->_init_filter($self->task_filters, 'schedule');
        $self->task_filters->{'schedule'}->{'until'} = $val;
    }
    
    unless($self->_has_filter($self->task_filters, "schedule")){
        return undef;
    }
    
    return $self->task_filters->{'schedule'}->{'until'};
}

sub _has_filter{
     my ($self, $parent, $field) = @_;
     return (exists $parent->{$field} && defined $parent->{$field});
}

sub _init_filter{
     my ($self, $parent, $field) = @_;
     unless($self->_has_filter($parent, $field)){
        $parent->{$field} = {};
     }
     
}

sub _init_list_filter{
     my ($self, $parent, $field) = @_;
     unless($self->_has_filter($parent, $field)){
        $parent->{$field} = [];
     }
     
}


__PACKAGE__->meta->make_immutable;

1;
