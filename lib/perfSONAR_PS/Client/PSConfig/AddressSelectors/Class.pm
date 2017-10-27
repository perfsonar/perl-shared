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

sub class{
    my ($self, $val) = @_;
    return $self->_field_name('class', $val);
}
  


  
__PACKAGE__->meta->make_immutable;

1;