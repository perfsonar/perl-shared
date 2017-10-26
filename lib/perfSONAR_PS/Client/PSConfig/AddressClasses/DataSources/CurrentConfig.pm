package perfSONAR_PS::Client::PSConfig::AddressClasses::DataSources::CurrentConfig;

use Mouse;

extends 'perfSONAR_PS::Client::PSConfig::AddressClasses::DataSources::BaseDataSource';

has 'type' => (
      is      => 'ro',
      default => sub {
          my $self = shift;
          $self->data->{'type'} = 'current-config';
          return $self->data->{'type'};
      },
  );

__PACKAGE__->meta->make_immutable;

1;