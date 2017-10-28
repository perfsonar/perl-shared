package perfSONAR_PS::Client::PSConfig::Groups::BaseP2PGroup;

use Mouse;
use perfSONAR_PS::Client::PSConfig::Groups::ExcludeSelfScope;
use perfSONAR_PS::Client::PSConfig::Groups::ExcludesAddressPair;

extends 'perfSONAR_PS::Client::PSConfig::Groups::BaseGroup';

has 'dimension_count' => (
      is      => 'ro',
      default => sub {
          return 2;
      },
  );

sub force_bidirectional{
    my ($self, $val) = @_;
    return $self->_field_bool('force-bidirectional', $val);
}

sub excludes_self{
    my ($self, $val) = @_;
    if(defined $val){
        if(perfSONAR_PS::Client::PSConfig::Groups::ExcludeSelfScope::VALID_VALUES->{$val}){
            $self->data->{'excludes-self'} = $val;
        }else{
            #invalid value - leave unchanged
        }
        
    }
    return $self->data->{'excludes-self'};
}

sub excludes{
    my ($self, $val) = @_;
    return $self->_field_class_list('excludes', 'perfSONAR_PS::Client::PSConfig::Groups::ExcludesAddressPair', $val);
}

sub add_exclude{
    my ($self, $val) = @_;
    $self->_add_field_class('excludes', 'perfSONAR_PS::Client::PSConfig::Groups::ExcludesAddressPair', $val);
}

__PACKAGE__->meta->make_immutable;

1;