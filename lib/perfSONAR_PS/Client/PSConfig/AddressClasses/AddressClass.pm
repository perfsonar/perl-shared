package perfSONAR_PS::Client::PSConfig::AddressClasses::AddressClass;

use Mouse;
use perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::FilterFactory;
use perfSONAR_PS::Client::PSConfig::AddressClasses::DataSources::DataSourceFactory;

extends 'perfSONAR_PS::Client::PSConfig::BaseMetaNode';

sub data_source{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'data-source'} = $val->data;
    }
    my $factory = new perfSONAR_PS::Client::PSConfig::AddressClasses::DataSources::DataSourceFactory();
    return $factory->build($self->data->{'data-source'});
}

sub match_filter{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'match-filter'} = $val->data;
    }
    my $factory = new perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::FilterFactory();
    return $factory->build($self->data->{'match-filter'});
}

sub exclude_filter{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'exclude-filter'} = $val->data;
    }
    my $factory = new perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::FilterFactory();
    return $factory->build($self->data->{'exclude-filter'});
}

sub archive_refs{
    my ($self, $val) = @_;
    if(defined $val){
        $self->data->{'archives'} = $val;
    }
    return $self->data->{'archives'};
}

sub add_archive_ref{
    my ($self, $val) = @_;
    
    unless(defined $val){
        return;
    }
    
    unless($self->data->{'archives'}){
        $self->data->{'archives'} = [];
    }

    push @{$self->data->{'archives'}}, $val;
}



__PACKAGE__->meta->make_immutable;

1;
