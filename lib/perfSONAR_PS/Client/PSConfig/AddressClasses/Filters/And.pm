package perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::And;

use Mouse;

extends 'perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::BaseOperandFilter';

has 'type' => (
      is      => 'ro',
      default => sub {
          my $self = shift;
          $self->data->{'type'} = 'and';
          return $self->data->{'type'};
      },
  );
  
__PACKAGE__->meta->make_immutable;

1;