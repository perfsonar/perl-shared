package perfSONAR_PS::Client::Utils;

use base 'Exporter';
use LWP::UserAgent;
use HTTP::Request;
use Params::Validate qw(:all);
use JSON qw(from_json);

our @EXPORT_OK = qw( send_http_request build_err_msg extract_url_uuid );

# establishes a HTTP connection and sends the message
sub send_http_request{
    my %parameters = validate( @_, { 
        connection_type => 1, 
        url => 1, 
        timeout => 1, 
        get_params => 0, 
        data => 0, 
        headers => 0, 
        verify_hostname => 0, 
        ca_certificate_file => 0, 
        ca_certificate_path => 0} );
    
    my $url = $parameters{url};
    my $param_count = 0;
    if($parameters{'get_params'} && scalar(keys %{$parameters{'get_params'}}) > 0){
        $url .= '?';
        foreach my $g(keys %{$parameters{'get_params'}}){
            $url .= '&' if($param_count > 0);
            $url .= "$g=" . $parameters{'get_params'}->{$g};
            $param_count++;
        }
    }
    
    my $ua = LWP::UserAgent->new;
    $ua->timeout($parameters->{timeout});
    $ua->env_proxy();
    unless($parameters->{ca_certificate_file} || $parameters->{ca_certificate_path}){
        $ua->ssl_opts(SSL_verify_mode => 0x00);
    }
    if(defined $parameters->{verify_hostname}){
        $ua->ssl_opts(verify_hostname => $parameters->verify_hostname);
    }else{
        $ua->ssl_opts(verify_hostname => 0);
    }
    $ua->ssl_opts(SSL_ca_file => $parameters->{ca_certificate_file}) if($parameters->{ca_certificate_file});
    $ua->ssl_opts(SSL_ca_path => $parameters->{ca_certificate_path}) if($parameters->{ca_certificate_path});
    push @{ $ua->requests_redirectable }, 'POST';
    push @{ $ua->requests_redirectable }, 'PUT';
    push @{ $ua->requests_redirectable }, 'DELETE';
    
    # Create a request
    my $req = HTTP::Request->new($parameters{connection_type} => $url);
    if($parameters{'headers'}){
        foreach my $h(keys %{$parameters{'headers'}}){
           $req->header($h => $parameters{'headers'}->{$h}); 
        }
    }
    $req->header('Content-Type' => 'application/json'); #always set this
    $req->content($parameters{data});
    
    # Pass request to the user agent and get a response back
    my $res = $ua->request($req);
    
    # Return response
    return $res;
}

sub build_err_msg {
    my $parameters = validate( @_, {http_response => 1});
    my $response = $parameters->{http_response};
    
    my $errmsg = $response->status_line;
    if($response->content){
        #try to parse json
        eval{
            my $response_json = from_json($response->content);
            if (exists $response_json->{'error'} && $response_json->{'error'}){
                $errmsg .= ': ' . $response_json->{'error'};
            }
        };
        if($@){
            $errmsg .= ': ' . $response->content;
        }
    }
    
    return $errmsg;
}

sub extract_url_uuid {
    my $parameters = validate( @_, {url => 1});
    my $url = $parameters->{'url'};
    chomp $url;
    $url =~ s/^"//;
    $url =~ s/"$//;
    my $task_uuid = "";
    if($url =~ /\/([0-9a-zA-Z\-]+)$/){
        $task_uuid = $1;
    }

    return $task_uuid;
}