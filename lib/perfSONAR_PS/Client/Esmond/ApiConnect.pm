package perfSONAR_PS::Client::Esmond::ApiConnect;

=head1 NAME

perfSONAR_PS::Client::Esmond::ApiConnect - A simple client for interacting with the Esmond Measurment Archive

=head1 DESCRIPTION

A client for interacting with the MA as implemented by esmond

=cut

use Mouse;
use Params::Validate qw(:all);
use  perfSONAR_PS::Client::Esmond::ApiFilters;
use  perfSONAR_PS::Client::Esmond::DataConnect;
use  perfSONAR_PS::Client::Esmond::Metadata;
use perfSONAR_PS::Client::Esmond::Utils qw(send_http_request build_err_msg);
use JSON qw(from_json);

our $VERSION = 3.4;

has 'url' => (is => 'rw', isa => 'Str');
has 'filters' => (is => 'rw', isa => 'perfSONAR_PS::Client::Esmond::ApiFilters', default => sub { new perfSONAR_PS::Client::Esmond::ApiFilters(); });
has 'error' => (is => 'ro', isa => 'Str', writer => '_set_error');

sub get_metadata() {
    my $self = shift;
    
    my %all_filters = (%{$self->filters->metadata_filters}, %{$self->filters->time_filters});
    my $response = send_http_request(
        connection_type => 'GET', 
        url => $self->url, 
        timeout => $self->filters->timeout,
        get_params => \%all_filters,
        ca_certificate_file => $self->filters->ca_certificate_file,
        ca_certificate_path => $self->filters->ca_certificate_path,
        verify_hostname => $self->filters->verify_hostname,
        headers => $self->filters->headers()
    );
     
    if(!$response->is_success){
        my $msg = build_err_msg(http_response => $response);
        $self->_set_error($msg);
        return;
    }
    my $response_metadata = from_json($response->content);
    if(! $response_metadata){
        $self->_set_error("No metadata objects returned.");
        return;
    }
    if(ref($response_metadata) ne 'ARRAY'){
        $self->_set_error("Metadata must be an array not " . ref($response_metadata));
        return;
    }
    
    my @md_objs = ();
    foreach my $md(@{$response_metadata}){
        push @md_objs, new perfSONAR_PS::Client::Esmond::Metadata(data => $md, url => $self->url, filters => $self->filters);
    }
    
    return \@md_objs;
}

sub get_data() {
    my ($self, $uri) = @_;
    my $data_client = new perfSONAR_PS::Client::Esmond::DataConnect(url => $self->url, filters => $self->filters, uri => $uri);
    my $data = $data_client->get_data();
    $self->_set_error($data_client->error) if($data_client->error);
    return $data;
}

__PACKAGE__->meta->make_immutable;

1;