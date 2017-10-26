package perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::BaseFilter;

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