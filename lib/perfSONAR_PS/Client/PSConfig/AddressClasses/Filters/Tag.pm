package perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::Tag;

use Mouse;

extends 'perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::BaseFilter';

has 'type' => (
      is      => 'ro',
      default => sub {
          my $self = shift;
          $self->data->{'type'} = 'tag';
          return $self->data->{'type'};
      },
  );

sub tag{
    my ($self, $val) = @_;
    return $self->_field('tag', $val);
}

__PACKAGE__->meta->make_immutable;

1;