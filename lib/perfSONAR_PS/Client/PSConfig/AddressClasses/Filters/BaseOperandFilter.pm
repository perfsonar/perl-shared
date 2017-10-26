package perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::BaseOperandFilter;

use Mouse;
use perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::FilterFactory;

extends 'perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::BaseFilter';

sub filters{
    my ($self, $val) = @_;
    if(defined $val){
        my @tmp_filters = ();
        foreach my $filter(@{$val}){
            push @tmp_filters, $filter->data;
        }
        $self->data->{'filters'} = \@tmp_filters;
    }
    my @tmp_filter_objs = ();
    my $factory = new perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::FilterFactory();
    foreach my $filter_data(@{$self->data->{'filters'}}){
        push @tmp_filter_objs, $factory->build($filter_data);
    }
    return \@tmp_filter_objs;
}

sub add_filter{
    my ($self, $val) = @_;
    
    unless(defined $val){
        return;
    }
    
    unless($self->data->{'filters'}){
        $self->data->{'filters'} = [];
    }

    push @{$self->data->{'filters'}}, $val->data;
}

__PACKAGE__->meta->make_immutable;

1;