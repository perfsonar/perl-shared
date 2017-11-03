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

has 'error' => (is => 'ro', isa => 'Str', writer => '_set_error');
has 'iter' => (is => 'ro', isa => 'Int', writer => '_set_iter', default => sub{0});

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

sub is_excluded_selectors {
    my ($self, $addr_sels) = @_;
    
    #override this if group has ways to exclude address selector combinations
    return 0;
}

sub is_excluded_addresses {
    my ($self, $addrs) = @_;
    
    #override this if group has ways to exclude address combinations
    return 0;
}

sub next{
    #Gets the next group of address selectors
    my ($self) = @_;
    
    #exit if reached max
    if($self->iter() > $self->max_iter()){
        return;
    }
    
    #Loop generalized for N dimensions that iterates through each dimension
    #and grabs next item in series. Once have tried all combos, returns undef
    my $working_size = 1;
    my @addr_sels = ();
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
    
    #increment iterator
    $self->_increment_iter();
    return @addr_sels;

}

sub reset {
    my ($self) = @_;
    $self->_reset_iter();
    $self->_reset();
}

sub _reset {
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