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

__PACKAGE__->meta->make_immutable;

1;