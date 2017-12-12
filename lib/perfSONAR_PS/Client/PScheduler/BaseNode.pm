package perfSONAR_PS::Client::PScheduler::BaseNode;

use Mouse;
use perfSONAR_PS::Client::PScheduler::ApiFilters;
use perfSONAR_PS::Client::Utils qw(send_http_request build_err_msg);
use JSON qw(to_json from_json);

has 'data' => (is => 'rw', isa => 'HashRef', default => sub { {} });
has 'url' => (is => 'rw', isa => 'Str|Undef');
has 'bind_address' => (is => 'rw', isa => 'Str|Undef');
has 'uuid' => (is => 'rw', isa => 'Str|Undef');
has 'filters' => (is => 'rw', isa => 'perfSONAR_PS::Client::PScheduler::ApiFilters', default => sub { new perfSONAR_PS::Client::PScheduler::ApiFilters()  });
has 'error' => (is => 'ro', isa => 'Str', writer => '_set_error');

sub json {
     my ($self, $formatting_params) = @_;
     $formatting_params = {} unless $formatting_params;
     unless(exists $formatting_params->{'utf8'} && defined $formatting_params->{'utf8'}){
        $formatting_params->{'utf8'} = 1;
     }
     unless(exists $formatting_params->{'canonical'} && defined $formatting_params->{'canonical'}){
        #makes JSON loading faster
        $formatting_params->{'canonical'} = 0;
     }
     
     return to_json($self->data, $formatting_params);
}

sub _post_url {
    my $self = shift;
    #return the api URL by default. override to build new URL
    return $self->url;
}

sub _delete_url {
    my $self = shift;
    unless($self->uuid()){
        die("Can't delete task without setting uuid");
    }
    my $delete_url = $self->_post_url();
    $delete_url .= "/" unless($delete_url =~ /\/$/);
    $delete_url .= $self->uuid();
    #return the api URL by default. override to build new URL
    return $delete_url;
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
        local_address => $self->bind_address,
        #headers => $self->filters->headers(),
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
        local_address => $self->bind_address,
        #headers => $self->filters->headers(),
        data => $data
    );
    
    if(!$response->is_success){
        my $msg = build_err_msg(http_response => $response);
        $self->_set_error($msg);
        return;
    }

    return $response->content;
}

sub _delete {
    my $self = shift;
    
    my $response = send_http_request(
        connection_type => 'DELETE', 
        url => $self->_delete_url(),
        timeout => $self->filters->timeout,
        ca_certificate_file => $self->filters->ca_certificate_file,
        ca_certificate_path => $self->filters->ca_certificate_path,
        verify_hostname => $self->filters->verify_hostname,
        local_address => $self->bind_address,
        #headers => $self->filters->headers(),
    );
    
    if(!$response->is_success){
        my $msg = build_err_msg(http_response => $response);
        $self->_set_error($msg);
        return;
    }

    return $response->content;
}

sub _has_field{
     my ($self, $parent, $field) = @_;
     return (exists $parent->{$field} && defined $parent->{$field});
}

sub _init_field{
     my ($self, $parent, $field) = @_;
     unless($self->_has_field($parent, $field)){
        $parent->{$field} = {};
     }
}

__PACKAGE__->meta->make_immutable;

1;