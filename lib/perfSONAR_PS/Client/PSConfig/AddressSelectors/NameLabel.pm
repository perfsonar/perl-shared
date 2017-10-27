package perfSONAR_PS::Client::PSConfig::AddressSelectors::NameLabel;

use Mouse;

extends 'perfSONAR_PS::Client::PSConfig::AddressSelectors::BaseAddressSelector';

has 'type' => (
      is      => 'ro',
      default => sub {
          #override this
          return "namelabel";
      },
  );

sub name{
    my ($self, $val) = @_;
    return $self->_field('name', $val);
}
 
sub label{
    my ($self, $val) = @_;
    return $self->_field('label', $val);
}

  
__PACKAGE__->meta->make_immutable;

1;