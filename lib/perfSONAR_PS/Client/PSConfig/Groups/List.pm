package perfSONAR_PS::Client::PSConfig::Groups::List;

use Mouse;
use JSON;
use perfSONAR_PS::Client::PSConfig::AddressSelectors::AddressSelectorFactory;

extends 'perfSONAR_PS::Client::PSConfig::Groups::BaseGroup';

has 'type' => (
      is      => 'ro',
      default => sub {
          my $self = shift;
          $self->data->{'type'} = 'list';
          return $self->data->{'type'};
      },
  );

has 'dimension_count' => (
      is      => 'ro',
      default => sub {
          return 1;
      },
  );

sub addresses{
    my ($self, $val) = @_;
    return $self->_field_class_factory_list('addresses', 
        'perfSONAR_PS::Client::PSConfig::AddressSelectors::BaseAddressSelector', 
        'perfSONAR_PS::Client::PSConfig::AddressSelectors::AddressSelectorFactory', 
        $val);
}

sub add_address{
    my ($self, $val) = @_;
    $self->_add_field_class('addresses', 'perfSONAR_PS::Client::PSConfig::AddressSelectors::BaseAddressSelector', $val);
}


__PACKAGE__->meta->make_immutable;

1;