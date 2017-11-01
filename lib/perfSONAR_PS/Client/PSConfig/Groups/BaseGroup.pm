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

has 'error' => (is => 'ro', isa => 'Str', writer => '_set_error');
has 'iter' => (is => 'ro', isa => 'Int', writer => '_set_iter', default => sub{0});

# sub dimension{
#     #accepts 1 int param indicating dimension to retrieve. Returns undef if not exists
#     die("Override this");
# }

sub default_address_label{
    my ($self, $val) = @_;
    return $self->_field('default-address-label', $val);
}

sub _increment_iter{
    my ($self) = @_;
    $self->_set_iter($self->iter() + 1);
}

sub _reset_iter{
    my ($self) = @_;
    $self->_set_iter(0);
}


__PACKAGE__->meta->make_immutable;

1;