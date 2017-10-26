package perfSONAR_PS::Client::PSConfig::AddressClasses::DataSources::BaseDataSource;

use Mouse;

extends 'perfSONAR_PS::Client::PSConfig::BaseNode';

has 'type' => (
      is      => 'ro',
      default => sub {
          #override this
          return undef;
      },
  );

__PACKAGE__->meta->make_immutable;

1;