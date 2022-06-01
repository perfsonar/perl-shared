package perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::JQ;

use Mouse;

use perfSONAR_PS::Client::PSConfig::JQTransform;

extends 'perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::BaseFilter';

has 'type' => (
      is      => 'ro',
      default => sub {
          my $self = shift;
          $self->data->{'type'} = 'jq';
          return $self->data->{'type'};
      },
  );

=item jq()

Get/sets JQTransform object for matching address properties

=cut

sub jq {
    my ($self, $val) = @_;
    return $self->_field_class('jq', 'perfSONAR_PS::Client::PSConfig::JQTransform', $val);
}

=item matches()

Return 0 or 1 depending on if given address match jq. JQ script must resturn boolean true 
or non-empty string. Boolean false or empty string means negatory.

=cut

sub matches{
    my ($self, $address, $psconfig) = @_;
    
    #can't do anything unless address is defined
    return 0 unless($address && $psconfig);
    
    #check jq
    my $jq = $self->jq();
    if($jq){
        #try to apply transformation
        my $jq_result = $jq->apply($address->data());
        if(!$jq_result){
            return 0;
        }
    }
    
    
    return 1;
}

__PACKAGE__->meta->make_immutable;

1;