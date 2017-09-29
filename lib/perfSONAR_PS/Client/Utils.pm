package perfSONAR_PS::Client::Utils;

use base 'Exporter';
use Log::Log4perl qw(get_logger);
use Net::INET6Glue::INET_is_INET6;
use LWP::UserAgent;
use LWP::Protocol::http;
use LWP::Protocol::https;
use HTTP::Request;
use HTTP::Response;
use Params::Validate qw(:all);
use JSON qw(from_json);
use URI::URL;
use Data::Validate::Domain qw(is_hostname);
use Data::Validate::IP qw(is_loopback_ipv4);
use Net::DNS;

our @EXPORT_OK = qw( send_http_request build_err_msg extract_url_uuid );

my $logger = get_logger(__PACKAGE__);

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
        ca_certificate_path => 0,
        local_address => 0,
        bind_map => 0,
        address_map => 0} );
    
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
    
    #set default timeout so we don't get stuck forever
    my $timeout = 120;
    if(exists $parameters{timeout} && defined $parameters{timeout}){
        $timeout = $parameters{timeout};
    }
    
    #init user agent
    my $ua = LWP::UserAgent->new;
    $ua->timeout($timeout);
    $ua->env_proxy();
    
    #lookup address if map provided
    my $address_map = $parameters{address_map};
    if($address_map && %{$address_map}){
        my $url_obj = new URI::URL($url);
        my $host = $url_obj->host;
        if(exists $address_map->{$host} && $address_map->{$host}){
            #if directly referenced, then use it
            $url_obj->host($address_map->{$host});
            $url = "$url_obj";
        }
    }
    
    #Determine where to bind locally, if needed
    my $bind_address = '';
    my $bind_map = $parameters{bind_map};
    if($bind_map && %{$bind_map}){
        #prefer bind map since it is more explicit
        my $url_obj = new URI::URL($url);
        my $host = $url_obj->host;
        if(exists $bind_map->{$host} && $bind_map->{$host}){
            #if directly referenced, then use it
            $bind_address = $bind_map->{$host};
        }elsif(exists $bind_map->{'_default'} && $bind_map->{'_default'}){
            #if use special work _default, then use that
            #should change to is_loopback_ip once we ditch CentOS 6
            $bind_address = $bind_map->{'_default'} unless(is_loopback_ipv4($host) || $host eq '::1' || $host =~ /^localhost/);
        }
    }
    if(!$bind_address && $parameters{local_address}){
        #if no bind_map but they provided more convenient local_address, then use that
        $bind_address = $parameters{local_address};
    }
    #apply address binding
    if($bind_address && LWP::UserAgent->can('local_address')){
        #local_address introduced in 5.834, CentOS 6 has 5.833
        $ua->local_address($bind_address);
    }elsif($bind_address){
        #older versions do it this way, which seems like it will break in parallel request cases
        # and possibly some more complicated cases. Should probably drop this when we drop CentOS 6
        @LWP::Protocol::http::EXTRA_SOCK_OPTS = ( LocalAddr => "$bind_address" );
        @LWP::Protocol::https::EXTRA_SOCK_OPTS = ( LocalAddr => "$bind_address" );
    }
    
    #remainder of user agent config
    unless($parameters{ca_certificate_file} || $parameters{ca_certificate_path}){
        $ua->ssl_opts(SSL_verify_mode => 0x00);
    }
    if(defined $parameters{verify_hostname}){
        $ua->ssl_opts(verify_hostname => $parameters{verify_hostname});
    }else{
        $ua->ssl_opts(verify_hostname => 0);
    }
    $ua->ssl_opts(SSL_ca_file => $parameters{ca_certificate_file}) if($parameters{ca_certificate_file});
    $ua->ssl_opts(SSL_ca_path => $parameters{ca_certificate_path}) if($parameters{ca_certificate_path});
    push @{ $ua->requests_redirectable }, 'POST';
    push @{ $ua->requests_redirectable }, 'PUT';
    push @{ $ua->requests_redirectable }, 'DELETE';
    
    # Create a request
    $logger->debug("Sending HTTP " . $parameters{connection_type} . " to $url" . ($bind_address ? " with local bind address $bind_address" : ""));
    my $req = HTTP::Request->new($parameters{connection_type} => $url);
    if($parameters{'headers'}){
        foreach my $h(keys %{$parameters{'headers'}}){
           $req->header($h => $parameters{'headers'}->{$h}); 
        }
    }
    $req->header('Content-Type' => 'application/json; charset=utf-8'); #always set this
    utf8::encode($parameters{data}) if($parameters{data});
    $req->content($parameters{data});
    
    # Pass request to the user agent and get a response back
    my $res = _send_request_timeout(agent=> $ua, request => $req, timeout => $timeout);
    #compensate for perl's lack of IPv4 fallback. If we get unreachable check if it is 
    # dual-stacked. If it is then try the IPv4 address.
    if($res->code == 500 && ($res->status_line =~ /unreachable/ || $res->status_line =~ /connect/)){
        my $url_obj = new URI::URL($url);
        my $hostname = $url_obj->host;
        #check we are working with a hostname
        if(is_hostname($hostname)){
            my $resolver = Net::DNS::Resolver->new;
            #check it has a AAAA record
            if($resolver->query($hostname, "AAAA")){
                #lookup A record
                my $dns_reply = $resolver->query($hostname, "A");
                if($dns_reply){
                    #try each A record returned until we get one that works
                    foreach my $dns_rec($dns_reply->answer){
                        if($dns_rec->type eq 'A'){
                            $url_obj->host($dns_rec->address);
                            $req->uri($url_obj);
                            $res = _send_request_timeout(agent=> $ua, request => $req, timeout => $timeout);
                            last if($res && $res->is_success);
                        }
                    }
                }
            }
        }
    }
    
    # Return response
    return $res;
}

sub _send_request_timeout {
    my %parameters = validate( @_, { 
            agent => 1,
            request => 1, 
            timeout => 1
        } );
    my $ua = $parameters{'agent'};
    my $timeout = $parameters{'timeout'};
    my $req = $parameters{'request'};
    my $res;
    $ua->timeout($timeout);
    eval{
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm $timeout;
        $res = $ua->request($req);
        alarm 0;
    };
    if($@){
        $res = new HTTP::Response(500, "Timeout connecting to server");
    }
    
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
