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
        
        push @{$self->_address_queue()}, @{$addr_combos};
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