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
    if(defined $val){
        $self->data->{'filter'} = $val->data;
    }
    my $factory = new perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::FilterFactory();
    return $factory->build($self->data->{'filter'});
}

__PACKAGE__->meta->make_immutable;

1;