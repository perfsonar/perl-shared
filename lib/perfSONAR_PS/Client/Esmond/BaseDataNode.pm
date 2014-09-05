package perfSONAR_PS::Client::Esmond::BaseDataNode;

use Mouse;
use perfSONAR_PS::Client::Esmond::DataPayload;
use perfSONAR_PS::Client::Esmond::Utils qw(send_http_request build_err_msg);
use JSON qw(from_json);
use URI::Split qw(uri_split uri_join);

extends 'perfSONAR_PS::Client::Esmond::BaseNode';

sub _uri {
    die "Must override _uri()";
}

override '_post_url' => sub {
    my $self = shift;
    my ($scheme, $auth, $path, $query, $frag) = uri_split($self->url);
    my $url = uri_join($scheme, $auth, $self->_uri());

    return $url;
};

sub get_data {
    my $self = shift;

    #build URL
    my ($scheme, $auth, $path, $query, $frag) = uri_split($self->url);
    my $url = uri_join($scheme, $auth, $self->_uri());
    
    #sent request
    my $response = send_http_request(
        connection_type => 'GET', 
        url => $url, 
        timeout => $self->filters->timeout,
        get_params => $self->filters->time_filters,
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
    my $response_data = from_json($response->content);
    if(! $response_data){
        $self->_set_error("No time series objects returned.");
        return;
    }
    if(ref($response_data) ne 'ARRAY'){
        $self->_set_error("Data must be an array not " . ref($response_data));
        return;
    }
    
    my @ts_objs = ();
    foreach my $d(@{$response_data}){
        push @ts_objs, new perfSONAR_PS::Client::Esmond::DataPayload(ts => $d->{'ts'}, val => $d->{'val'});
    }
    return \@ts_objs;
}

__PACKAGE__->meta->make_immutable;

1;
