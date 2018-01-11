package perfSONAR_PS::Client::PSConfig::AddressSelectors::Class;

use Mouse;

extends 'perfSONAR_PS::Client::PSConfig::AddressSelectors::BaseAddressSelector';

has 'type' => (
      is      => 'ro',
      default => sub {
          #override this
          return "class";
      },
  );

=item class()

Gets/sets class

=cut

sub class{
    my ($self, $val) = @_;
    return $self->_field_name('class', $val);
}

=item select()

Selects addresses that belong to given class and returns as list of name/label/address
HashRefs.

=cut

sub select{
    my ($self, $psconfig) = @_;
    
    #make sure we have a config
    unless($psconfig){
        return (undef, undef);
    }
    
    #make sure we have a name
    my $class_name = $self->class();
    unless($class_name){
        return (undef, undef);
    }
    
    #make sure it matches an address
    my $address_class = $psconfig->address_class($class_name);
    unless($address_class){
        return (undef, undef);
    }
    
    return $address_class->select($psconfig);
}

__PACKAGE__->meta->make_immutable;

1;