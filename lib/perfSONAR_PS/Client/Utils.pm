package perfSONAR_PS::Client::Utils;

##
# Prior to JSON::XS version 3.0, booleans are not handled correctly which can cause issue
# for JSON::Validator. The block below detects this, sets PERL_JSON_BACKEND environment
# variable to JSON::PP then reloads JSON and any JSON subpackages
BEGIN {
    #detect version, if above 3.0 then don't do anything
    if (eval "require JSON::XS" && $JSON::XS::VERSION < 3.0) {
        #init list of JSON subpackages so we make sure to re-import
        my @json_subpackages = ();
        # list of packages JSON will re-import on its own
        my %skip_packages = (
            'JSON/PP.pm' => 1,
            'JSON/XS.pm' => 1
        );
        #if json already loaded, then we need to reload it and subpackages
        if ($INC{'JSON.pm'} && JSON::backend()->isa("JSON::XS")) {
            # get list of JSON:: subpackages
            foreach my $module(sort keys %INC){
                next if($module !~ /^JSON\// || $skip_packages{$module});
                push @json_subpackages, $module;
            }
            #delete JSON package
            use Symbol;
            Symbol::delete_package('JSON');
            #delete JSON and sub-packages from $INC
            delete $INC{'JSON.pm'};
            foreach my $json_subpackage(@json_subpackages){
                delete $INC{$json_subpackage};
            }
        }

        #set environment variable
        $ENV{PERL_JSON_BACKEND} = 'JSON::PP';
        #load JSON module
        require JSON;
        JSON->import;
        #load JSON subpackages
        foreach my $json_subpackage(@json_subpackages){
            require $json_subpackage;
            $json_subpackage =~ s/\.pm$//;
            $json_subpackage =~ s/\//::/g;
            $json_subpackage->import;
        }
    }
}

use base 'Exporter';
use Log::Log4perl qw(get_logger);
use Mojo::UserAgent;
use Mojo::Transaction::HTTP;
use Mojo::Message::Response;
use Params::Validate qw(:all);
use JSON qw(from_json);
use URI::URL;
use Data::Validate::Domain qw(is_hostname);
use Data::Validate::IP qw(is_loopback_ipv4);
use Net::DNS;

our @EXPORT_OK = qw( send_http_request build_err_msg extract_url_uuid );

my $logger;
if(Log::Log4perl->initialized()) {
    #this is intended to be a lib reliant on someone else initializing env
    #detect if they did but quietly move on if not
    #anything using $logger will need to check if defined
    $logger = get_logger(__PACKAGE__);
}


# establishes a HTTP connection and sends the message
sub send_http_request{
    my %parameters = validate( @_, { 
        connection_type => 1, 
        url => 1, 
        timeout => 1, 
        get_params => 0, 
        data => 0, 
        max_redirects => 0,
        headers => 0, 
        ca_certificate_file => 0, 
        verify_hostname => 0, #deprecated
        ca_certificate_path => 0, #deprecated
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
    
    #set default redirects to something greater than 0
    my $max_redirects = 3;
    if(exists $parameters{max_redirects} && defined $parameters{max_redirects}){
        $max_redirects = $parameters{max_redirects};
    }
    
    #init user agent
    my $ua = Mojo::UserAgent->new;
    $ua->connect_timeout($timeout);
    $ua->request_timeout($timeout);
    $ua->max_redirects($max_redirects);
    $ua->proxy->detect;
    
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
    if($bind_address){
        $ua->local_address($bind_address);
    }
    
    #remainder of user agent config
    $ua->ca($parameters{ca_certificate_file}) if($parameters{ca_certificate_file});
    
    # Create a request
    $logger->debug("Sending HTTP " . $parameters{connection_type} . " to $url" . ($bind_address ? " with local bind address $bind_address" : "")) if($logger);
    my $tx = Mojo::Transaction::HTTP->new;
    $tx->req->method($parameters{connection_type});
    $tx->req->url->parse($url);
    if($parameters{'headers'}){
        foreach my $h(keys %{$parameters{'headers'}}){
           $tx->req->headers->header($h => $parameters{'headers'}->{$h}); 
        }
    }
    $tx->req->headers->content_type('application/json; charset=utf-8'); #always set this
    utf8::encode($parameters{data}) if($parameters{data});
    $tx->req->body($parameters{data}) if($parameters{data});
    
    # Pass request to the user agent and get a response back
    my $res = _send_request_timeout(agent=> $ua, request => $tx, timeout => $timeout);
    my $status_line = $res->get_start_line_chunk(0);
    #compensate for perl's lack of IPv4 fallback. If we get unreachable check if it is 
    # dual-stacked. If it is then try the IPv4 address.
    if($res->code == 500 && ($status_line =~ /unreachable/ || $status_line =~ /connect/)){
        my $url_obj = new URI::URL($url);
        my $hostname = $url_obj->host;
        $hostname =~ s/\[//;
        $hostname =~ s/\]//;
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
                            $tx->req->url->parse("$url_obj");
                            $res = _send_request_timeout(agent=> $ua, request => $tx->req, timeout => $timeout);
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
    $ua->connect_timeout($timeout);
    $ua->request_timeout($timeout);
    eval{
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm $timeout;
        my $res_tx = $ua->start($req);
        $res = $res_tx->res;
        alarm 0;
    };
    if($@){
        $res = new Mojo::Message::Response();
        $res->code(500);
        $res->message("Timeout connecting to server");
    }
    
    return $res;
}


sub build_err_msg {
    my $parameters = validate( @_, {http_response => 1});
    my $response = $parameters->{http_response};
    
    my $errmsg = $response->get_start_line_chunk(0);
    if($response->body){
        #try to parse json
        eval{
            my $response_json = from_json($response->body);
            if (exists $response_json->{'error'} && $response_json->{'error'}){
                $errmsg .= ': ' . $response_json->{'error'};
            }
        };
        if($@){
            $errmsg .= ': ' . $response->body;
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

1;
