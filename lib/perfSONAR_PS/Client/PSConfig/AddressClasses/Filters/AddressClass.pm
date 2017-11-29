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

sub matches{
    my ($self, $address, $psconfig) = @_;
    
    #return match if no tag defined
    my $class_name = $self->class();
    return 1 unless($class_name);
    
    #can't do anything unless address is defined
    return 0 unless($address);

    #if can't find address class, fail
    my $addr_class = $psconfig->address_class($class_name);
    return 0 unless($addr_class);
    
    return $addr_class->matches($address, $psconfig);
}

__PACKAGE__->meta->make_immutable;

1;