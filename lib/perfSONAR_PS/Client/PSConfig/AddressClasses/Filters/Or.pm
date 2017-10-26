package perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::Or;

use Mouse;

extends 'perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::BaseOperandFilter';

has 'type' => (
      is      => 'ro',
      default => sub {
          my $self = shift;
          $self->data->{'type'} = 'or';
          return $self->data->{'type'};
      },
  );
  
__PACKAGE__->meta->make_immutable;

1;