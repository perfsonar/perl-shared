package perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::Host;

use Mouse;

extends 'perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::BaseFilter';

has 'type' => (
      is      => 'ro',
      default => sub {
          my $self = shift;
          $self->data->{'type'} = 'host';
          return $self->data->{'type'};
      },
  );

sub site{
    my ($self, $val) = @_;
    return $self->_field('site', $val);
}

sub tag{
    my ($self, $val) = @_;
    return $self->_field('tag', $val);
}

sub no_agent{
    my ($self, $val) = @_;
    return $self->_field_bool('no-agent', $val);
}

sub matches{
    my ($self, $address, $psconfig) = @_;
    
    #can't do anything unless address is defined
    return 0 unless($address && $psconfig);

    #get the host, return 0 if can't find it
    my $host = $psconfig->host($address->host_ref());
    return 0 unless($host);
    
    #check site, if defined
    if($self->site()){
        if($host->site()){
            #unless sites match, fail
            if(lc($self->site()) ne lc($host->site())){
                return 0;
            }
        }else{
            #no site so no match
            return 0;
        }
    }
    
    #check tags, if defined
    if($self->tag()){
        if($host->tags()){
            my $tag_match = 0;
            foreach my $host_tag(@{$host->tags()}){
                if(lc($host_tag) eq lc($self->tag())){
                    $tag_match = 1;
                    last;
                }
            }
            return 0 unless($tag_match);
        }else{
            #no tags so no match
            return 0;
        }
    }
    
    
    #no_agent always defined (default false), so normalize booleans and compare
    my $filter_no_agent = $self->no_agent() ? 1 : 0;
    my $host_no_agent = $host->no_agent() ? 1 : 0;
    return 0 unless($filter_no_agent == $host_no_agent);
    
    
    return 1;
}

__PACKAGE__->meta->make_immutable;

1;