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

=item fetch()

A function for accepting a config object and returning a HashRef of Address objects

=cut

sub fetch{
    my ($self, $config) = @_;
    
    die("Override this");
}

__PACKAGE__->meta->make_immutable;

1;