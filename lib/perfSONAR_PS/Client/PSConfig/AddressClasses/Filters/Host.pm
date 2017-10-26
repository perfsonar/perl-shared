package perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::Host;

use Mouse;

extends 'perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::BaseFilter';

has 'type' => (
      is      => 'ro',
      default => sub {
          my $self = shift;
          $self->data->{'type'} = 'host';
          return $self->data->{'type'};
      },
  );

sub site{
    my ($self, $val) = @_;
    return $self->_field('site', $val);
}

sub tag{
    my ($self, $val) = @_;
    return $self->_field('tag', $val);
}

sub no_agent{
    my ($self, $val) = @_;
    return $self->_field_bool('no-agent', $val);
}

__PACKAGE__->meta->make_immutable;

1;