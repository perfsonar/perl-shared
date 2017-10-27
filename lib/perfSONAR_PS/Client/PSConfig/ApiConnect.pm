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
use perfSONAR_PS::Client::PSConfig::Config;

our $VERSION = 4.1;

has 'url' => (is => 'rw', isa => 'Str');
has 'save_filename' => (is => 'rw', isa => 'Str');
has 'bind_address' => (is => 'rw', isa => 'Str|Undef');
has 'filters' => (is => 'rw', isa => 'perfSONAR_PS::Client::PSConfig::ApiFilters', default => sub { new perfSONAR_PS::Client::PSConfig::ApiFilters(); });
has 'error' => (is => 'ro', isa => 'Str', writer => '_set_error');

sub _config_from_file() {
    my $self = shift;
    
    #remove prefix
    my $filename = $self->url();
    chomp $filename;
    $filename =~ s/^file:\/\///g;
    my $psconfig;
    
    eval{
        my $json_text = do {
           open(my $fh, "<:encoding(UTF-8)", $filename) or die("Can't open $filename: $!");
           local $/;
           <$fh>
        };

        my $json_obj = from_json($json_text);
        if(!$json_obj){
            $self->_set_error("No config object found $filename.");
            return;
        }
        
        $psconfig = new perfSONAR_PS::Client::PSConfig::Config(data => $json_obj);
    };
    if($@){
        $self->_set_error($@);
        return;
    }
    
    return $psconfig;
}

sub _config_from_http() {
    my $self = shift;
    my $psconfig;
    
    eval{
        my $response = send_http_request(
            connection_type => 'GET', 
            url => $self->url, 
            timeout => $self->filters->timeout,
            ca_certificate_file => $self->filters->ca_certificate_file,
            ca_certificate_path => $self->filters->ca_certificate_path,
            verify_hostname => $self->filters->verify_hostname,
            local_address => $self->bind_address,
            #headers => $self->filters->headers()
        );

        if(!$response->is_success){
            my $msg = build_err_msg(http_response => $response);
            $self->_set_error($msg);
            return;
        }

        my $response_json = from_json($response->content);
        if(!$response_json){
            $self->_set_error("No task objects returned.");
            return;
        }
        
        $psconfig = new perfSONAR_PS::Client::PSConfig::Config(data => $response_json);
    };
    if($@){
        $self->_set_error($@);
        return;
    }
    
    return $psconfig;
}

sub get_config() {
    my $self = shift;
    
    #Make sure we have a URL
    if(!$self->url()){
        $self->_set_error("No URL defined.");
        return;
    }
    
    #Retrieve based on URL type
    if($self->url() =~ /^https?:\/\//){
        #http or https
        return $self->_config_from_http();
    }elsif($self->url() =~ /^file:\/\//){
        #local file
        return $self->_config_from_file();
    }else{
        $self->_set_error("Unrecognized URL type (" . $self->url() . "). Must start with http:// or file://");
        return;
    }
    
    
}

sub save_config() {
    my ($self, $psconfig, $formatting_params) = @_;
    $formatting_params = {} unless $formatting_params;
    my $filename = $self->save_filename();
    chomp $filename;
    $filename =~ s/^file:\/\///g;
    unless($filename) {
        $self->_set_error("No save_filename set");
        return;
    }
    
    eval{
        open(my $fh, ">:encoding(UTF-8)", $filename) or die("Can't open $filename: $!");
        print $fh $psconfig->json($formatting_params);
        close $fh;
    };
    if($@){
        $self->_set_error($@);
    }
}



__PACKAGE__->meta->make_immutable;

1;