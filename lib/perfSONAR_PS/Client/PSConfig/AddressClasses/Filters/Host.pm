package perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::Host;

use Mouse;

use perfSONAR_PS::Client::PSConfig::JQTransform;

extends 'perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::BaseFilter';

has 'type' => (
      is      => 'ro',
      default => sub {
          my $self = shift;
          $self->data->{'type'} = 'host';
          return $self->data->{'type'};
      },
  );


=item site()

Gets/sets sites

=cut

sub site{
    my ($self, $val) = @_;
    return $self->_field('site', $val);
}

=item tag()

Gets/sets tag

=cut

sub tag{
    my ($self, $val) = @_;
    return $self->_field('tag', $val);
}

=item no_agent()

Gets/sets no-agent

=cut

sub no_agent{
    my ($self, $val) = @_;
    return $self->_field_bool('no-agent', $val);
}

=item jq()

Get/sets JQTransform object for matching host properties

=cut

sub jq {
    my ($self, $val) = @_;
    return $self->_field_class('jq', 'perfSONAR_PS::Client::PSConfig::JQTransform', $val);
}

=item matches()

Return 0 or 1 depending on if given address and Config object match this host definition.
Must match all given parameters.

=cut

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
    
    #check jq
    my $jq = $self->jq();
    if($jq){
        #try to apply transformation
        my $jq_result = $jq->apply($host->data());
        if(!$jq_result){
            return 0;
        }
    }
    
    
    return 1;
}

__PACKAGE__->meta->make_immutable;

1;