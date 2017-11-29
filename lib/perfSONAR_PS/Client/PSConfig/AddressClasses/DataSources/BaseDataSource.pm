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

sub fetch{
    my ($self, $config) = @_;
    
    #a function for accepting a config and returning an array of Address objects
    die("Override this");
}

__PACKAGE__->meta->make_immutable;

1;