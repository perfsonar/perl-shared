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
    if(defined $val){
        $self->data->{'name'} = $val;
    }
    return $self->data->{'name'};
}
 
sub label{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'label'} = $val;
    }
    return $self->data->{'label'};
}


  
__PACKAGE__->meta->make_immutable;

1;