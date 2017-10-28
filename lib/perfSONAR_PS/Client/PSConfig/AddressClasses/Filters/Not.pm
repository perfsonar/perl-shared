package perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::Not;

use Mouse;
use perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::FilterFactory;

extends 'perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::BaseFilter';

has 'type' => (
      is      => 'ro',
      default => sub {
          my $self = shift;
          $self->data->{'type'} = 'not';
          return $self->data->{'type'};
      },
  );

sub filter{
    my ($self, $val) = @_;
    return $self->_field_class_factory('filter', 
        'perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::BaseFilter',
        'perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::FilterFactory', 
        $val);
}

__PACKAGE__->meta->make_immutable;

1;