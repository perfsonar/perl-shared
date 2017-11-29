package perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::Tag;

use Mouse;

extends 'perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::BaseFilter';

has 'type' => (
      is      => 'ro',
      default => sub {
          my $self = shift;
          $self->data->{'type'} = 'tag';
          return $self->data->{'type'};
      },
  );

sub tag{
    my ($self, $val) = @_;
    return $self->_field('tag', $val);
}

sub matches{
    my ($self, $address, $psconfig) = @_;
    
    #return match if no tag defined
    my $tag = lc($self->tag());
    return 1 unless($tag);
    
    #can't do anything unless address is defined
    return 0 unless($address);

    #try to match tags in address
    if($address->tags()){
        foreach my $addr_tag(@{$address->tags()}){
            return 1 if(lc($addr_tag) eq $tag);
        }
    }
        
    #try to match tags in host
    my $host = $psconfig->host($address->host_ref());
    return 0 unless($host);
    if($host->tags()){
        foreach my $host_tag(@{$host->tags()}){
            return 1 if(lc($host_tag) eq $tag);
        }
    }
    
    
    return 0;
}

__PACKAGE__->meta->make_immutable;

1;