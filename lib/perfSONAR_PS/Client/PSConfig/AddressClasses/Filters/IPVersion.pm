package perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::IPVersion;

use Mouse;

extends 'perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::BaseFilter';

has 'type' => (
      is      => 'ro',
      default => sub {
          my $self = shift;
          $self->data->{'type'} = 'ip-version';
          return $self->data->{'type'};
      },
  );

sub ip_version{
    my ($self, $val) = @_;
    return $self->_field('ip-version', $val);
}

__PACKAGE__->meta->make_immutable;

1;