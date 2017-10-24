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
    if(defined $val){
        $self->data->{'disabled'} = $val ? JSON::true : JSON::false;
    }
    return $self->data->{'disabled'} ? 1 : 0;
}

__PACKAGE__->meta->make_immutable;

1;