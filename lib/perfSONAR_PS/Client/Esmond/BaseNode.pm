package perfSONAR_PS::Client::Esmond::BaseNode;

use Mouse;
use perfSONAR_PS::Client::Esmond::ApiFilters;
use perfSONAR_PS::Client::Esmond::Utils qw(send_http_request build_err_msg);

has 'data' => (is => 'rw', isa => 'HashRef', default => sub { {} });
has 'url' => (is => 'rw', isa => 'Str|Undef');
has 'filters' => (is => 'rw', isa => 'perfSONAR_PS::Client::Esmond::ApiFilters|Undef');
has 'error' => (is => 'ro', isa => 'Str', writer => '_set_error');

sub _post_url {
    my $self = shift;
    #return the api URL by default. override to build new URL
    return $self->url;
}

sub _post {
    my ($self, $data) = @_;
    
    my $response = send_http_request(
        connection_type => 'POST', 
        url => $self->_post_url(),
        timeout => $self->filters->timeout,
        ca_certificate_file => $self->filters->ca_certificate_file,
        ca_certificate_path => $self->filters->ca_certificate_path,
        verify_hostname => $self->filters->verify_hostname,
        headers => $self->filters->headers(),
        data => $data
    );
    
    if(!$response->is_success){
        my $msg = build_err_msg(http_response => $response);
        $self->_set_error($msg);
        return;
    }

    return $response->content;
}

sub _put {
    my ($self, $data) = @_;
    
    my $response = send_http_request(
        connection_type => 'PUT', 
        url => $self->_post_url(),
        timeout => $self->filters->timeout,
        ca_certificate_file => $self->filters->ca_certificate_file,
        ca_certificate_path => $self->filters->ca_certificate_path,
        verify_hostname => $self->filters->verify_hostname,
        headers => $self->filters->headers(),
        data => $data
    );
    
    if(!$response->is_success){
        my $msg = build_err_msg(http_response => $response);
        $self->_set_error($msg);
        return;
    }

    return $response->content;
}

__PACKAGE__->meta->make_immutable;

1;