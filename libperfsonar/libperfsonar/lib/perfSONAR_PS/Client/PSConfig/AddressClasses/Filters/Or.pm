package perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::Or;

use Mouse;

extends 'perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::BaseOperandFilter';

has 'type' => (
      is      => 'ro',
      default => sub {
          my $self = shift;
          $self->data->{'type'} = 'or';
          return $self->data->{'type'};
      },
  );

=item matches()

Return 0 or 1 depending on if given address and Config object matches any of the filters

=cut

sub matches{
    my ($self, $address, $psconfig) = @_;
    
    #return match if no filters defined
    my $filters = $self->filters();
    
    #can't do anything unless address is defined
    return 0 unless($address);

    #if any match, then success
    foreach my $filter(@{$filters}){
        return 1 if($filter->matches($address, $psconfig));
    }
    
    return 0;
}

__PACKAGE__->meta->make_immutable;

1;