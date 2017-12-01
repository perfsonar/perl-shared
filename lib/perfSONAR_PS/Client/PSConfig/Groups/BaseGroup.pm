package perfSONAR_PS::Client::PSConfig::Groups::BaseGroup;

use Mouse;

extends 'perfSONAR_PS::Client::PSConfig::BaseMetaNode';

has 'type' => (
      is      => 'ro',
      default => sub {
          #override this
          return undef;
      },
  );

has 'started' => (is => 'ro', isa => 'Bool', writer => '_set_started');
has 'error' => (is => 'ro', isa => 'Str', writer => '_set_error');
has 'iter' => (is => 'ro', isa => 'Int', writer => '_set_iter', default => sub{0});
has '_address_queue' => (is => 'ro', isa => 'ArrayRef', default => sub{[]});
has '_psconfig' => (is => 'ro', isa => 'perfSONAR_PS::Client::PSConfig::Config|Undef', writer => '_set_psconfig');


sub default_address_label{
    my ($self, $val) = @_;
    return $self->_field('default-address-label', $val);
}

sub dimension_count{
    my $self = shift;
    #returns number of dimensions. made sub so can be dynamic
    die("Override this");
}

sub dimension{
    my $self = shift;
    my @indices = @_;
    #accepts list of indices for each dimension and returns AddressSelector
    die("Override this");
}

sub dimension_size{
    my ($self, $index) = @_;
    #accepts dimension for which you want the size and return int
    die("Override this");
}

sub select_addresses{
    my ($self, $addr_nlas) = @_;
    #given an array of HashRefs containing {name=> '..', label=> '..', address=> Address }
    # find all the combose an return and array of arrarys of BaseAddress objects where things
    # like remote address and labelled address have been worked-out.
    die("Override this");
}

sub is_excluded_selectors {
    my ($self, $addr_sels) = @_;
    
    #override this if group has ways to exclude address selector combinations
    return 0;
}

sub start{
    #Gets the next group of address selectors
    my ($self, $psconfig) = @_;
    
    #if already started, return
    if($self->started()){
        return;
    }
    
    $self->_reset_iter();
    $self->_set_psconfig($psconfig);
    $self->_start();
    $self->_set_started(1);
}

sub _start {
    my ($self) = @_;
    #override this if you have local state to set on start
    return;
}

sub next{
    #Gets the next group of address selectors
    my ($self) = @_;
    
    #only run this if we ran start
    unless($self->started()){
        return;
    }
    
    #Loop generalized for N dimensions that iterates through each dimension
    #and grabs next item in series.
    while(!@{$self->_address_queue()}){
        my $excluded = 1;
        my @addr_sels = ();
        while($excluded){
            #exit if reached max
            if($self->iter() > $self->max_iter()){
                return;
            }
            
            my $working_size = 1;
            @addr_sels = ();
            for(my $i = $self->dimension_count(); $i > 0; $i--){
                my $index;
        
                if($i == $self->dimension_count()){
                    $index = $self->iter() % $self->dimension_size($i - 1);
                }else{
                    $working_size *= $self->dimension_size($i);
                    $index = int($self->iter() / $working_size);
                }
        
                my $addr_sel = $self->dimension($i - 1, $index);
                unshift @addr_sels, $addr_sel;
            }

            $excluded = $self->is_excluded_selectors(\@addr_sels);
            $self->_increment_iter();
        }
    
        #we now have the selectors, time to expand
        my @addr_nlas = ();
        foreach my $addr_sel(@addr_sels){
            push @addr_nlas, $addr_sel->select($self->_psconfig());
        }

        #we now have the name,label,addresses, time to combine in group specific way
        my $addr_combos = $self->select_addresses(\@addr_nlas);
        
        push @{$self->_address_queue()}, @{$addr_combos} if($addr_combos);
    }
        
    my $addresses = shift @{$self->_address_queue()};
    return @{$addresses};
}

sub stop {
    my ($self) = @_;
    
    $self->_set_started(0);
    $self->_reset_iter();
    $self->_stop();
    $self->_set_psconfig(undef);
}

sub _stop {
    my ($self) = @_;
    #override this if you have local state to reset
    return;
}

sub max_iter{
    my ($self) = @_;
    
    my $max_size = 1;
    for(my $i = 0; $i < $self->dimension_count(); $i++){
        $max_size *= $self->dimension_size($i);
    }
    
    return $max_size -1;
}

sub select_address {
    ##
    # Selects address given a address obj, label and remote address key. Once we get 
    # >2 dimensions remote key may be aggregate of other dimensions
    my ($self, $local_addr, $local_label, $remote_addr_key ) = @_;
    
    #validate
    unless($local_addr){
        return;
    }
    
    #set label to default
    my $default_label = $self->default_address_label();
    if($default_label && !$local_label){
        $local_label = $default_label;
    }
    
    #check for remotes first - if remote_addr_key undef then below is undef
    my $remote_addr_entry = $local_addr->remote_address($remote_addr_key);
    if($remote_addr_entry){
        my $remote_label_entry = $remote_addr_entry->label($local_label);
        if($remote_label_entry){
            #return label with disabled and no-agent settings merged-in
            return $self->merge_parents($remote_label_entry, [$local_addr, $remote_addr_entry]);
        }elsif(!$local_label && $remote_addr_entry->address()){
            #return remote address with disabled and no-agent settings merged-in
            # only fall back to this if no label specified
            return $self->merge_parents($remote_addr_entry, [$local_addr]);
        }else{
            #if we have a remote entry but we don't have a match, then skip this address
            return;
        }
    }
    
    #check for label next
    if($local_label){
        my $label_entry = $local_addr->label($local_label);
        if($label_entry){
            return return $self->merge_parents($label_entry, [$local_addr]);
        }else{
            #if we have a label but we don't have a match, then skip this address
            return;
        }
    }
        
    #finally, if none of the above work, just use the address obj as is
    return $local_addr;
}

sub merge_parents {
    my ($self, $addr, $parents) = @_;
    
    #make sure we have required params
    return unless($addr && $parents);
    
    #iterate through parents
    foreach my $parent(@{$parents}){
        $addr->_set_parent_no_agent(1) if($parent->no_agent() || $parent->_parent_no_agent());
        $addr->_set_parent_disabled(1) if($parent->disabled() || $parent->_parent_disabled());
        if($parent->can('host_ref')){
            #only Address has host_ref,so set that as parent
            $addr->_set_parent_address($parent->address());
            if($parent->host_ref()){
                $addr->_set_parent_host_ref($parent->host_ref());
            }
        }elsif($parent->_parent_host_ref()){
            $addr->_set_parent_host_ref($parent->_parent_host_ref());
        }
    }
    
    return $addr;
}

sub _increment_iter{
    my ($self) = @_;
    $self->_set_iter($self->iter() + 1);
}

sub _reset_iter{
    my ($self) = @_;
    $self->_set_iter(0);
}

__PACKAGE__->meta->make_immutable;

1;