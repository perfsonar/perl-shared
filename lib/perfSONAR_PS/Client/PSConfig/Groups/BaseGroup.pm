package perfSONAR_PS::Client::PSConfig::Groups::BaseGroup;

use Mouse;

extends 'perfSONAR_PS::Client::PSConfig::BaseMetaNode';

has 'type' => (
      is      => 'ro',
      default => sub {
          #override this
          return undef;
      },
  );

has 'dimension_count' => (
      is      => 'ro',
      default => sub {
          #override this
          return undef;
      },
  );

# sub dimension{
#     #accepts 1 int param indicating dimension to retrieve. Returns undef if not exists
#     die("Override this");
# }

sub default_address_label{
    my ($self, $val) = @_;
    return $self->_field('default-address-label', $val);
}


__PACKAGE__->meta->make_immutable;

1;