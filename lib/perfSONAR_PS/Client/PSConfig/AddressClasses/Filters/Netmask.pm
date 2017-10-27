package perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::Netmask;

use Mouse;

extends 'perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::BaseFilter';

has 'type' => (
      is      => 'ro',
      default => sub {
          my $self = shift;
          $self->data->{'type'} = 'netmask';
          return $self->data->{'type'};
      },
  );

sub netmask{
    my ($self, $val) = @_;
    return $self->_field_ipcidr('netmask', $val);
}

__PACKAGE__->meta->make_immutable;

1;