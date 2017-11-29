package perfSONAR_PS::Client::PSConfig::AddressClasses::DataSources::RequestingAgent;

use Mouse;

extends 'perfSONAR_PS::Client::PSConfig::AddressClasses::DataSources::BaseDataSource';

has 'type' => (
      is      => 'ro',
      default => sub {
          my $self = shift;
          $self->data->{'type'} = 'requesting-agent';
          return $self->data->{'type'};
      },
  );


sub fetch{
    my ($self, $psconfig) = @_;
    
    #make sure we have a config
    unless($psconfig){
        return;
    }
    
    return $psconfig->requesting_agent_addresses();
}

__PACKAGE__->meta->make_immutable;

1;