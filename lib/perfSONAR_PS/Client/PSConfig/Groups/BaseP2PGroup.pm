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

=item dimension_count()

Returns 2 since there are two dimensions (src, dst) in point-to-point test

=cut

sub dimension_count{
    return 2;
}

=item excludes_self()

Gets/sets excludes-self

=cut

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

=item excludes()

Gets/sets excludes as ArrayRef

=cut

sub excludes{
    my ($self, $val) = @_;
    return $self->_field_class_list('excludes', 'perfSONAR_PS::Client::PSConfig::Groups::ExcludesAddressPair', $val);
}

=item exclude()

Gets/sets exclude as specified index

=cut

sub exclude{
    my ($self, $index, $val) = @_;
    return $self->_field_class_list_item('excludes', $index, 'perfSONAR_PS::Client::PSConfig::Groups::ExcludesAddressPair', $val);
}

=item add_exclude()

Adds exclude to list

=cut

sub add_exclude{
    my ($self, $val) = @_;
    $self->_add_field_class('excludes', 'perfSONAR_PS::Client::PSConfig::Groups::ExcludesAddressPair', $val);
}

=item is_excluded_selectors()

Given list of two address selectors, returns 1 if should be excluded, 0 otherwise

=cut

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
            $self->_exclude_checksum_map()->{$a_checksum}->{$b_checksum}){
            $exclude_this = 1;
        }
    }
    
    return $exclude_this;
}

=item is_excluded_addresses()

Given two addresses and two hosts, returns 1 if should be excluded and 0 otehrwise

=cut

sub is_excluded_addresses {
    my ($self, $a_addr, $b_addr, $a_host, $b_host) = @_;
    
    #validate
    unless($a_addr && $b_addr){
        return 1;
    }
    
    #default exclude_self is host
    my $exclude_self = $self->excludes_self();
    unless($exclude_self){
        $exclude_self = perfSONAR_PS::Client::PSConfig::Groups::ExcludeSelfScope::HOST;
    }
    
    #check host scope
    if($exclude_self eq perfSONAR_PS::Client::PSConfig::Groups::ExcludeSelfScope::HOST){
        if($a_host && $b_host && lc($a_host) eq lc($b_host)){
            return 1;
        }
    }
    #check address scope
    if($exclude_self eq perfSONAR_PS::Client::PSConfig::Groups::ExcludeSelfScope::HOST ||
        $exclude_self eq perfSONAR_PS::Client::PSConfig::Groups::ExcludeSelfScope::ADDRESS){
        my $addr1 = $a_addr->_parent_address() ? $a_addr->_parent_address() : $a_addr->address();
        my $addr2 = $b_addr->_parent_address() ? $b_addr->_parent_address() : $b_addr->address();
        if($addr1 && $addr2 && $addr1 eq $addr2){
            return 1;
        }
    } 
    
    #don't exclude
    return 0;
}

=item select_addresses()

Given two name/label/address HashRefs, returns the a tuple of Address objects. If excluded
return and empty list 

=cut

sub select_addresses{
    my ($self, $addr_nlas) = @_;
    
    #validate
    unless($addr_nlas && ref $addr_nlas eq 'ARRAY' && @{$addr_nlas} == 2){
        return;
    }
    
    my @address_pairs = ();
    foreach my $a_addr_nla(@{$addr_nlas->[0]}){
        foreach my $b_addr_nla(@{$addr_nlas->[1]}){
            my $a_addr = $self->select_address(
                $a_addr_nla->{'address'}, 
                $a_addr_nla->{'label'}, 
                $b_addr_nla->{'name'}
            );
            my $b_addr = $self->select_address(
                $b_addr_nla->{'address'}, 
                $b_addr_nla->{'label'}, 
                $a_addr_nla->{'name'}
            );
            my $a_host = $a_addr_nla->{'address'}->host_ref();
            my $b_host = $b_addr_nla->{'address'}->host_ref();

            #pass host directly since AddressLabel won't have host_ref
            unless($self->is_excluded_addresses($a_addr, $b_addr, $a_host, $b_host)){
                push @address_pairs, [$a_addr, $b_addr];
            }
        }
    }
    
    return \@address_pairs;
}

sub _stop {
    my ($self) = @_;
    $self->_set_exclude_checksum_map(undef);
}



__PACKAGE__->meta->make_immutable;

1;