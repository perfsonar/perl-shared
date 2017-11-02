package perfSONAR_PS::Client::PSConfig::Groups::BaseP2PGroup;

use Mouse;
use perfSONAR_PS::Client::PSConfig::Groups::ExcludeSelfScope;
use perfSONAR_PS::Client::PSConfig::Groups::ExcludesAddressPair;

extends 'perfSONAR_PS::Client::PSConfig::Groups::BaseGroup';

has '_exclude_checksum_map' => (
      is      => 'ro',
      isa => 'HashRef|Undef',
      default => sub { undef },
      writer => '_set_exclude_checksum_map'
  );

sub dimension_count{
    return 2;
}

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

sub exclude{
    my ($self, $index, $val) = @_;
    return $self->_field_class_list_item('excludes', $index, 'perfSONAR_PS::Client::PSConfig::Groups::ExcludesAddressPair', $val);
}

sub add_exclude{
    my ($self, $val) = @_;
    $self->_add_field_class('excludes', 'perfSONAR_PS::Client::PSConfig::Groups::ExcludesAddressPair', $val);
}

sub is_excluded_selectors {
    my ($self, $addr_sels) = @_;

    #validate
    unless($addr_sels && ref $addr_sels eq 'ARRAY' && @{$addr_sels} == 2){
        return;
    }
    
    #Process excludes
    my $exclude_this = 0;
    my @excludes = @{$self->excludes()};
    if(@excludes > 0){
        #Init _exclude_checksum_map if needed
        unless($self->_exclude_checksum_map()){
            my $tmp_map;
            foreach my $excl_pair(@excludes){
                my $local_checksum = $excl_pair->local_address()->checksum();
                $tmp_map->{$local_checksum} = {} unless(exists $tmp_map->{$local_checksum});
                foreach my $target(@{$excl_pair->target_addresses()}){
                    $tmp_map->{$local_checksum}->{$target->checksum()} = 1;
                }
            }
            $self->_set_exclude_checksum_map($tmp_map);
        }
        
        #check 
        my $a_checksum = $addr_sels->[0]->checksum();
        my $b_checksum = $addr_sels->[1]->checksum();
        if(exists $self->_exclude_checksum_map()->{$a_checksum} &&
            exists $self->_exclude_checksum_map()->{$a_checksum}->{$b_checksum} &&
            $self->_exclude_checksum_map()->{$a_checksum}->{$b_checksum}){
            $exclude_this = 1;
        }
    }
    
    return $exclude_this;
}


__PACKAGE__->meta->make_immutable;

1;