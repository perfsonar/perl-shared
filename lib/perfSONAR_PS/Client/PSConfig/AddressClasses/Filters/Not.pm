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

sub matches{
    my ($self, $address, $psconfig) = @_;
    
    #return match if no filter defined
    my $filter = $self->filter();
    return 1 unless($filter);
    
    #can't do anything unless address is defined
    return 0 unless($address);
    
    return $filter->matches($address, $psconfig) ? 0 : 1;
}

__PACKAGE__->meta->make_immutable;

1;