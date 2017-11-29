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

sub matches{
    my ($self, $address, $psconfig) = @_;
    
    #given Address object and config, return whether matches filter
    die("Override this");
}

__PACKAGE__->meta->make_immutable;

1;