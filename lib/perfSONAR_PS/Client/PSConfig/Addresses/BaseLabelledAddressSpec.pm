package perfSONAR_PS::Client::PSConfig::Addresses::BaseLabelledAddressSpec;

use Mouse;
use perfSONAR_PS::Client::PSConfig::Addresses::AddressLabelSpec;

extends 'perfSONAR_PS::Client::PSConfig::Addresses::BaseAddressSpec';

sub labels{
    my ($self, $val) = @_;
    
    if(defined $val){
        $self->data->{'labels'} = {};
        foreach my $v(keys %{$val}){
            my $tmp_label = $val->{$v}->data;
            $self->data->{'labels'}->{$v} = $tmp_label;
        }
    }
    
    my %labels = ();
    foreach my $label(keys %{$self->data->{'labels'}}){
        my $tmp_label_obj = $self->label($label);
        $labels{$label} = $tmp_label_obj;
    }
    
    return \%labels;
}

sub label{
    my ($self, $field, $val) = @_;
    
    unless(defined $field){
        return undef;
    }
    
    if(defined $val){
        $self->_init_field($self->data, 'labels');
        $self->data->{'labels'}->{$field} = $val->data;
    }
    
    unless($self->_has_field($self->data, "labels")){
        return undef;
    }
    
    unless($self->_has_field($self->data->{'labels'}, $field)){
        return undef;
    }
    
    return new perfSONAR_PS::Client::PSConfig::Addresses::AddressLabelSpec(
            data => $self->data->{'labels'}->{$field}
        );
} 

sub label_names{
    my ($self) = @_;
    return $self->_get_map_names("labels");
} 

sub remove_label {
    my ($self, $field) = @_;
    $self->_remove_map_item('labels', $field);
}

sub remove_labels {
    my ($self) = @_;
    $self->_remove_map('labels');
}


__PACKAGE__->meta->make_immutable;

1;