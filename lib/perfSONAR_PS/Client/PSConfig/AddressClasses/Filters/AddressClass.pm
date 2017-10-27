package perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::AddressClass;

use Mouse;

extends 'perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::BaseFilter';

has 'type' => (
      is      => 'ro',
      default => sub {
          my $self = shift;
          $self->data->{'type'} = 'address-class';
          return $self->data->{'type'};
      },
  );

sub class{
    my ($self, $val) = @_;
    return $self->_field_name('class', $val);
}

__PACKAGE__->meta->make_immutable;

1;