package perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::Netmask;

use Mouse;
use Data::Validate::IP qw(is_ipv4 is_ipv6);
use Net::CIDR qw(cidrlookup);
use perfSONAR_PS::Utils::DNS qw(resolve_address);

extends 'perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::BaseFilter';

has 'type' => (
      is      => 'ro',
      default => sub {
          my $self = shift;
          $self->data->{'type'} = 'netmask';
          return $self->data->{'type'};
      },
  );

=item netmask()

Gets/sets netmask

=cut

sub netmask{
    my ($self, $val) = @_;
    return $self->_field_ipcidr('netmask', $val);
}

=item matches()

Return 0 or 1 depending on if given address and Config object match the provided netmask

=cut

sub matches{
    my ($self, $address_obj, $psconfig) = @_;
    
    #can't do anything unless address is defined
    return 0 unless($address_obj && $address_obj->address());
    
    #get address
    my $address = $address_obj->address();
    my @ip_addresses = ();

    if(is_ipv6($address) || is_ipv4($address)){
        push @ip_addresses, $address;
    }else {
        push @ip_addresses, resolve_address($address);
    }
    
    my $matches;
    my $netmask = $self->netmask();
    foreach my $ip(@ip_addresses){
        eval {
            if(cidrlookup($ip, $netmask)){
                $matches = 1;
            }
        };
        last if $matches;
    }

    return $matches;
}

__PACKAGE__->meta->make_immutable;

1;