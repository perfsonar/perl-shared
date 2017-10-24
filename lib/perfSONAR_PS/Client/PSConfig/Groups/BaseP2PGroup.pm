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
    if(defined $val){
        $self->data->{'force-bidirectional'} = $val ? JSON::true : JSON::false;
    }
    return $self->data->{'force-bidirectional'} ? 1 : 0;
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
    if(defined $val){
        my @tmp_excls = ();
        foreach my $excl(@{$val}){
            push @tmp_excls, $excl->data;
        }
        $self->data->{'excludes'} = \@tmp_excls;
    }
    
    my @tmp_excls_objs = ();
    foreach my $excl_data(@{$self->data->{'excludes'}}){
        push @tmp_excls_objs, new perfSONAR_PS::Client::PSConfig::Groups::ExcludesAddressPair(data => $excl_data);
    }
    return \@tmp_excls_objs;
}

sub add_exclude{
    my ($self, $val) = @_;
    
    unless(defined $val){
        return;
    }
    
    unless($self->data->{'excludes'}){
        $self->data->{'excludes'} = [];
    }

    push @{$self->data->{'excludes'}}, $val->data;
}

__PACKAGE__->meta->make_immutable;

1;