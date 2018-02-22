package perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::IPVersion;

use Mouse;
use Data::Validate::IP qw(is_ipv4 is_ipv6);
use perfSONAR_PS::Utils::DNS qw(resolve_address);

extends 'perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::BaseFilter';

has 'type' => (
      is      => 'ro',
      default => sub {
          my $self = shift;
          $self->data->{'type'} = 'ip-version';
          return $self->data->{'type'};
      },
  );

=item ip_version()

Gets/set ip-version

=cut

sub ip_version{
    my ($self, $val) = @_;
    return $self->_field_ipversion('ip-version', $val);
}

=item matches()

Return 0 or 1 depending on if given address and Config object match ip version.

=cut

sub matches{
    my ($self, $address_obj, $psconfig) = @_;
    
    #can't do anything unless address is defined
    return 0 unless($address_obj && $address_obj->address());
    
    #get address
    my $address = $address_obj->address();
    my @ip_addresses = ();

    if (is_ipv6( $address ) || is_ipv4( $address )) {
        push @ip_addresses, $address;
    }
    else {
        push @ip_addresses, resolve_address($address);
    }

    my $matches;
    foreach my $ip (@ip_addresses) {
        if ($self->ip_version() == 4 && is_ipv4($ip)) {
            $matches = 1;
            last;
        }

        if ($self->ip_version() == 6 && is_ipv6($ip)) {
            $matches = 1;
            last;
        }
    }

    return $matches;
}

__PACKAGE__->meta->make_immutable;

1;