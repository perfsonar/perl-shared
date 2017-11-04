package perfSONAR_PS::Client::PSConfig::AddressSelectors::BaseAddressSelector;

use Mouse;

extends 'perfSONAR_PS::Client::PSConfig::BaseNode';

has 'type' => (
      is      => 'ro',
      default => sub {
          #override this
          return undef;
      },
  );

sub disabled{
    my ($self, $val) = @_;
    return $self->_field_bool('disabled', $val);
}

sub select{
    my ($self, $config) = @_;
    
    #a function for accepting a config and returning an array containing maps with:
    # 1. "label" => The label to use when selecting an address. undef if unable to determine
    # 2. "name" => The name of the address
    # 3. "address" => A map of matching addresses where the key is the name and the value is an Address object 
    die("Override this");
}

__PACKAGE__->meta->make_immutable;

1;