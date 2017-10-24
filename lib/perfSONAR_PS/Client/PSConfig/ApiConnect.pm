package perfSONAR_PS::Client::PSConfig::ApiConnect;

=head1 NAME

perfSONAR_PS::Client::PSConfig::ApiConnect - A client for interacting with pSConfig

=head1 DESCRIPTION

A client for interacting with pSConfig

=cut

use Mouse;
use Params::Validate qw(:all);
use perfSONAR_PS::Client::Utils qw(send_http_request build_err_msg extract_url_uuid);
use JSON qw(from_json to_json);

use perfSONAR_PS::Client::PSConfig::ApiFilters;

our $VERSION = 4.1;

has 'url' => (is => 'rw', isa => 'Str');
has 'bind_address' => (is => 'rw', isa => 'Str|Undef');
has 'filters' => (is => 'rw', isa => 'perfSONAR_PS::Client::PSConfig::ApiFilters', default => sub { new perfSONAR_PS::Client::PSConfig::ApiFilters(); });
has 'error' => (is => 'ro', isa => 'Str', writer => '_set_error');

sub get_config_from_file() {
    #TODO
}

sub get_config_from_url() {
    my $self = shift;
    
     my $response = send_http_request(
        connection_type => 'GET', 
        url => $self->url, 
        timeout => $self->filters->timeout,
        ca_certificate_file => $self->filters->ca_certificate_file,
        ca_certificate_path => $self->filters->ca_certificate_path,
        verify_hostname => $self->filters->verify_hostname,
        local_address => $self->bind_address,,
        #headers => $self->filters->headers()
    );

    if(!$response->is_success){
        my $msg = build_err_msg(http_response => $response);
        $self->_set_error($msg);
        return;
    }

    my $response_json = from_json($response->content);
    if(! $response_json){
        $self->_set_error("No task objects returned.");
        return;
    }
    
    return new perfSONAR_PS::Client::PSConfig::Config(
        data => $task_response_json
    );
}

__PACKAGE__->meta->make_immutable;

1;