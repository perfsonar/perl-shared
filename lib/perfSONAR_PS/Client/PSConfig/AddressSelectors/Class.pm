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
    if(defined $val){
        $self->data->{'class'} = $val;
    }
    return $self->data->{'class'};
}
  


  
__PACKAGE__->meta->make_immutable;

1;